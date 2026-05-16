package com.fileini.storysizer.service.group.service;

import com.fileini.storysizer.service.group.dto.GroupEstimationDashboardDTO;
import com.fileini.storysizer.service.group.model.GroupEstimation;
import com.fileini.storysizer.service.group.model.GroupEstimationVote;
import com.fileini.storysizer.service.group.model.GroupMember;
import com.fileini.storysizer.service.group.repository.GroupEstimationRepository;
import com.fileini.storysizer.service.group.repository.GroupEstimationVoteRepository;
import com.fileini.storysizer.service.group.repository.GroupMemberRepository;
import com.fileini.storysizer.service.group.util.SizerCalculator;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.OptionalDouble;
import java.util.function.ToIntFunction;
import java.util.stream.Collectors;

@Service
public class GroupEstimationService {

    private final GroupEstimationRepository estimationRepo;
    private final GroupEstimationVoteRepository voteRepo;
    private final GroupMemberRepository memberRepo;
    private final GroupService groupService;

    public GroupEstimationService(GroupEstimationRepository estimationRepo,
                                  GroupEstimationVoteRepository voteRepo,
                                  GroupMemberRepository memberRepo,
                                  GroupService groupService) {
        this.estimationRepo = estimationRepo;
        this.voteRepo = voteRepo;
        this.memberRepo = memberRepo;
        this.groupService = groupService;
    }

    // ─── Queries ─────────────────────────────────────────────────────────────

    public List<GroupEstimation> getByGroup(Long groupId) {
        return estimationRepo.findByGroupIdOrderByCreatedAtDesc(groupId);
    }

    /** All group estimations where the user has a pending (TO_SIZE) vote */
    public List<GroupEstimation> getPendingForUser(String userId) {
        return voteRepo.findByUserIdAndStatus(userId, "TO_SIZE").stream()
            .map(v -> estimationRepo.findById(v.getGroupEstimationId()).orElse(null))
            .filter(e -> e != null)
            .collect(Collectors.toList());
    }

    /** All group estimations the user has any vote on (pending + submitted), for the feed */
    public List<GroupEstimation> getFeedForUser(String userId) {
        List<GroupEstimationVote> pending = voteRepo.findByUserIdAndStatus(userId, "TO_SIZE");
        List<GroupEstimationVote> submitted = voteRepo.findByUserIdAndStatus(userId, "SUBMITTED");

        // Pending first, then submitted (most recent first)
        return java.util.stream.Stream.concat(
            pending.stream(),
            submitted.stream().sorted((a, b) -> b.getSubmittedAt() == null ? 0 :
                a.getSubmittedAt() == null ? 1 : b.getSubmittedAt().compareTo(a.getSubmittedAt()))
        )
        .map(v -> estimationRepo.findById(v.getGroupEstimationId()).orElse(null))
        .filter(e -> e != null)
        .collect(Collectors.toList());
    }

    public long countPendingForUser(String userId) {
        return voteRepo.countByUserIdAndStatus(userId, "TO_SIZE");
    }

    /** Vote status of the requesting user on a specific group estimation */
    public GroupEstimationVote getMyVote(Long groupEstimationId, String userId) {
        return voteRepo.findByGroupEstimationIdAndUserId(groupEstimationId, userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Vote not found"));
    }

    // ─── Create ──────────────────────────────────────────────────────────────

    /**
     * Creates a new GroupEstimation and initializes a TO_SIZE vote for every
     * active member of the group. Only an ADMIN can do this.
     */
    @Transactional
    public GroupEstimation createGroupEstimation(Long groupId, String title, String requestingUserId) {
        groupService.requireAdmin(groupId, requestingUserId);
        groupService.requireGroup(groupId);

        GroupEstimation estimation = estimationRepo.save(new GroupEstimation(groupId, title, requestingUserId));

        List<GroupMember> members = memberRepo.findByGroupId(groupId);
        for (GroupMember m : members) {
            voteRepo.save(new GroupEstimationVote(estimation.getId(), m.getUserId(), m.getDisplayName()));
        }

        return estimation;
    }

    // ─── Vote ────────────────────────────────────────────────────────────────

    @Transactional
    public GroupEstimationVote submitVote(Long groupEstimationId, String userId,
                                          int complexity, int reach, int dimensions, int risk, int interaction) {
        GroupEstimationVote vote = voteRepo.findByGroupEstimationIdAndUserId(groupEstimationId, userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                "No vote record found — you may not be a member of this group"));

        vote.setComplexity(clamp(complexity));
        vote.setReach(clamp(reach));
        vote.setDimensions(clamp(dimensions));
        vote.setRisk(clamp(risk));
        vote.setInteraction(clamp(interaction));
        vote.setSizer(SizerCalculator.calculate(complexity, reach, dimensions, risk, interaction));
        vote.setStatus("SUBMITTED");
        vote.setSubmittedAt(Instant.now());

        return voteRepo.save(vote);
    }

    // ─── Admin operations ────────────────────────────────────────────────────

    @Transactional
    public GroupEstimation rename(Long groupEstimationId, String newTitle, String requestingUserId) {
        GroupEstimation estimation = requireEstimation(groupEstimationId);
        groupService.requireAdmin(estimation.getGroupId(), requestingUserId);
        estimation.setTitle(newTitle);
        estimation.setUpdatedAt(Instant.now());
        return estimationRepo.save(estimation);
    }

    /**
     * Restart: resets all votes to TO_SIZE and clears submitted values.
     */
    @Transactional
    public void restart(Long groupEstimationId, String requestingUserId) {
        GroupEstimation estimation = requireEstimation(groupEstimationId);
        groupService.requireAdmin(estimation.getGroupId(), requestingUserId);

        List<GroupEstimationVote> votes = voteRepo.findByGroupEstimationId(groupEstimationId);
        for (GroupEstimationVote v : votes) {
            v.setStatus("TO_SIZE");
            v.setComplexity(null);
            v.setReach(null);
            v.setDimensions(null);
            v.setRisk(null);
            v.setInteraction(null);
            v.setSizer(null);
            v.setSubmittedAt(null);
            voteRepo.save(v);
        }
    }

    @Transactional
    public void delete(Long groupEstimationId, String requestingUserId) {
        GroupEstimation estimation = requireEstimation(groupEstimationId);
        groupService.requireAdmin(estimation.getGroupId(), requestingUserId);

        List<GroupEstimationVote> votes = voteRepo.findByGroupEstimationId(groupEstimationId);
        voteRepo.deleteAll(votes);
        estimationRepo.delete(estimation);
    }

    // ─── Dashboard ───────────────────────────────────────────────────────────

    public GroupEstimationDashboardDTO getDashboard(Long groupEstimationId, String requestingUserId) {
        GroupEstimation estimation = requireEstimation(groupEstimationId);
        // Any member can see the dashboard
        memberRepo.findByGroupIdAndUserId(estimation.getGroupId(), requestingUserId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Not a member"));

        List<GroupEstimationVote> allVotes = voteRepo.findByGroupEstimationId(groupEstimationId);
        List<GroupEstimationVote> submitted = allVotes.stream()
            .filter(v -> "SUBMITTED".equals(v.getStatus())).collect(Collectors.toList());

        String groupName = groupService.requireGroup(estimation.getGroupId()).getName();

        GroupEstimationDashboardDTO dto = new GroupEstimationDashboardDTO();
        dto.setGroupEstimationId(groupEstimationId);
        dto.setTitle(estimation.getTitle());
        dto.setGroupName(groupName);
        dto.setTotalVoters(allVotes.size());
        dto.setSubmittedVoters(submitted.size());

        if (!submitted.isEmpty()) {
            dto.setComplexityAvg(avg(submitted, v -> v.getComplexity()));
            dto.setReachAvg(avg(submitted, v -> v.getReach()));
            dto.setDimensionsAvg(avg(submitted, v -> v.getDimensions()));
            dto.setRiskAvg(avg(submitted, v -> v.getRisk()));
            dto.setInteractionAvg(avg(submitted, v -> v.getInteraction()));

            dto.setComplexityAgreement(agreement(submitted, v -> v.getComplexity()));
            dto.setReachAgreement(agreement(submitted, v -> v.getReach()));
            dto.setDimensionsAgreement(agreement(submitted, v -> v.getDimensions()));
            dto.setRiskAgreement(agreement(submitted, v -> v.getRisk()));
            dto.setInteractionAgreement(agreement(submitted, v -> v.getInteraction()));
        }

        return dto;
    }

    // ─── Private helpers ─────────────────────────────────────────────────────

    private GroupEstimation requireEstimation(Long id) {
        return estimationRepo.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Group estimation not found"));
    }

    private static int clamp(int v) { return Math.max(1, Math.min(5, v)); }

    private double avg(List<GroupEstimationVote> votes, ToIntFunction<GroupEstimationVote> getter) {
        return votes.stream().mapToInt(getter).average().orElse(0.0);
    }

    /**
     * Agreement index: 1.0 = perfect agreement, 0.0 = max disagreement.
     * Uses normalized standard deviation (max std-dev on range 1-5 is 2.0).
     */
    private double agreement(List<GroupEstimationVote> votes, ToIntFunction<GroupEstimationVote> getter) {
        if (votes.size() < 2) return 1.0;
        double mean = avg(votes, getter);
        double variance = votes.stream()
            .mapToDouble(v -> Math.pow(getter.applyAsInt(v) - mean, 2))
            .average().orElse(0.0);
        double stdDev = Math.sqrt(variance);
        double maxStdDev = 2.0; // on a 1-5 scale
        return Math.max(0.0, 1.0 - (stdDev / maxStdDev));
    }
}
