package com.fileini.storysizer.service.group.service;

import com.fileini.storysizer.service.group.dto.GroupDetailDTO;
import com.fileini.storysizer.service.group.mail.ResendMailClient;
import com.fileini.storysizer.service.group.model.GroupInvitation;
import com.fileini.storysizer.service.group.model.GroupMember;
import com.fileini.storysizer.service.group.model.SizingGroup;
import com.fileini.storysizer.service.group.repository.GroupInvitationRepository;
import com.fileini.storysizer.service.group.repository.GroupMemberRepository;
import com.fileini.storysizer.service.group.repository.GroupRepository;
import com.fileini.storysizer.service.group.util.TokenUtil;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GroupService {

    private final GroupRepository groupRepo;
    private final GroupMemberRepository memberRepo;
    private final GroupInvitationRepository invitationRepo;
    private final ResendMailClient mailClient;

    public GroupService(GroupRepository groupRepo, GroupMemberRepository memberRepo,
                        GroupInvitationRepository invitationRepo, ResendMailClient mailClient) {
        this.groupRepo = groupRepo;
        this.memberRepo = memberRepo;
        this.invitationRepo = invitationRepo;
        this.mailClient = mailClient;
    }

    // ─── Groups ──────────────────────────────────────────────────────────────

    /** Returns all non-deleted groups the user is a member (or admin) of */
    public List<GroupDetailDTO> myGroups(String userId, String displayName, String email) {
        return memberRepo.findByUserId(userId).stream()
            .map(m -> {
                SizingGroup g = groupRepo.findByIdAndDeletedAtIsNull(m.getGroupId()).orElse(null);
                if (g == null) return null;
                List<GroupMember> members = memberRepo.findByGroupId(g.getId());
                List<GroupInvitation> pending = invitationRepo.findByGroupIdAndStatus(g.getId(), "PENDING");
                return new GroupDetailDTO(g, m.getRole(), members, pending);
            })
            .filter(dto -> dto != null)
            .collect(Collectors.toList());
    }

    /** Full group detail (with member list and pending invitations) */
    public GroupDetailDTO getGroupDetail(Long groupId, String requestingUserId) {
        SizingGroup group = requireGroup(groupId);
        GroupMember me = memberRepo.findByGroupIdAndUserId(groupId, requestingUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Not a member"));
        List<GroupMember> members = memberRepo.findByGroupId(groupId);
        List<GroupInvitation> pending = invitationRepo.findByGroupIdAndStatus(groupId, "PENDING");
        return new GroupDetailDTO(group, me.getRole(), members, pending);
    }

    @Transactional
    public GroupDetailDTO createGroup(String name, String userId, String displayName, String email) {
        SizingGroup group = groupRepo.save(new SizingGroup(name, userId));
        GroupMember admin = memberRepo.save(new GroupMember(group.getId(), userId, displayName, email, "ADMIN"));
        return new GroupDetailDTO(group, "ADMIN", List.of(admin), List.of());
    }

    @Transactional
    public GroupDetailDTO renameGroup(Long groupId, String newName, String requestingUserId) {
        requireAdmin(groupId, requestingUserId);
        SizingGroup group = requireGroup(groupId);
        group.setName(newName);
        groupRepo.save(group);
        return getGroupDetail(groupId, requestingUserId);
    }

    @Transactional
    public void deleteGroup(Long groupId, String requestingUserId) {
        requireAdmin(groupId, requestingUserId);
        SizingGroup group = requireGroup(groupId);
        group.setDeletedAt(Instant.now());
        groupRepo.save(group);
    }

    // ─── Members ─────────────────────────────────────────────────────────────

    @Transactional
    public GroupMember promoteToAdmin(Long groupId, String targetUserId, String requestingUserId) {
        requireAdmin(groupId, requestingUserId);
        GroupMember target = memberRepo.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member not found"));
        target.setRole("ADMIN");
        return memberRepo.save(target);
    }

    @Transactional
    public void removeMember(Long groupId, String targetUserId, String requestingUserId) {
        requireAdmin(groupId, requestingUserId);
        if (targetUserId.equals(requestingUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cannot remove yourself");
        }
        GroupMember target = memberRepo.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Member not found"));
        memberRepo.delete(target);
    }

    // ─── Invitations ─────────────────────────────────────────────────────────

    /**
     * Creates invitation and sends email synchronously.
     * Throws on mail failure (caller gets 500 → frontend shows retry).
     */
    @Transactional
    public GroupInvitation invite(Long groupId, String invitedEmail,
                                  String requestingUserId, String requesterDisplayName,
                                  String appBaseUrl) {
        requireAdmin(groupId, requestingUserId);
        requireGroup(groupId);
        String email = invitedEmail.toLowerCase().trim();

        if (memberRepo.existsByGroupIdAndUserId(groupId, email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "User is already a member");
        }
        if (invitationRepo.existsByGroupIdAndInvitedEmailAndStatus(groupId, email, "PENDING")) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Invitation already pending for this email");
        }

        String rawToken = TokenUtil.generateRawToken();
        String tokenHash = TokenUtil.hashToken(rawToken);

        GroupInvitation invitation = invitationRepo.save(new GroupInvitation(
            groupId, email, requestingUserId, tokenHash,
            Instant.now().plus(7, ChronoUnit.DAYS)
        ));

        SizingGroup group = requireGroup(groupId);
        String joinLink = appBaseUrl + "/join-group?token=" + rawToken;

        // Synchronous send — throws on failure, rolling back the transaction
        mailClient.sendInvite(email, requesterDisplayName, group.getName(), joinLink);

        return invitation;
    }

    @Transactional
    public void cancelInvite(Long groupId, Long invitationId, String requestingUserId) {
        requireAdmin(groupId, requestingUserId);
        GroupInvitation inv = invitationRepo.findById(invitationId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invitation not found"));
        if (!inv.getGroupId().equals(groupId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invitation does not belong to this group");
        }
        if (!"PENDING".equals(inv.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Invitation is not pending");
        }
        inv.setStatus("CANCELED");
        invitationRepo.save(inv);
    }

    /**
     * Accepts an invite using the raw token from the email link.
     * The email claim from the JWT must match the invitedEmail.
     */
    @Transactional
    public GroupDetailDTO acceptInvite(String rawToken, String userId, String displayName, String userEmail) {
        String tokenHash = TokenUtil.hashToken(rawToken);
        GroupInvitation inv = invitationRepo.findByTokenHash(tokenHash)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invalid invite link"));

        if (!"PENDING".equals(inv.getStatus())) {
            throw new ResponseStatusException(HttpStatus.GONE, "This invite has already been used or canceled");
        }
        if (Instant.now().isAfter(inv.getExpiresAt())) {
            inv.setStatus("EXPIRED");
            invitationRepo.save(inv);
            throw new ResponseStatusException(HttpStatus.GONE, "This invite has expired");
        }
        if (!inv.getInvitedEmail().equalsIgnoreCase(userEmail)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "This invite was sent to a different email address");
        }
        if (memberRepo.existsByGroupIdAndUserId(inv.getGroupId(), userId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Already a member of this group");
        }

        memberRepo.save(new GroupMember(inv.getGroupId(), userId, displayName, userEmail, "MEMBER"));
        inv.setStatus("ACCEPTED");
        invitationRepo.save(inv);

        return getGroupDetail(inv.getGroupId(), userId);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    public SizingGroup requireGroup(Long groupId) {
        return groupRepo.findByIdAndDeletedAtIsNull(groupId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Group not found"));
    }

    public void requireAdmin(Long groupId, String userId) {
        GroupMember m = memberRepo.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Not a member"));
        if (!"ADMIN".equals(m.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Admin role required");
        }
    }
}
