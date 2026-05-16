package com.fileini.storysizer.service.group.controller;

import com.fileini.storysizer.service.group.dto.GroupDetailDTO;
import com.fileini.storysizer.service.group.model.GroupInvitation;
import com.fileini.storysizer.service.group.model.GroupMember;
import com.fileini.storysizer.service.group.service.GroupService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Internal REST API consumed by the GraphQL gateway.
 * Authentication is handled by the gateway; this service is cluster-internal only.
 * User context is passed via HTTP headers set by the gateway:
 *   X-User-Id    — JWT sub (stable user identifier)
 *   X-User-Name  — preferred_username (display)
 *   X-User-Email — email claim
 */
@RestController
@RequestMapping("/groups")
public class GroupController {

    private final GroupService groupService;

    @Value("${storysizer.app.base-url}")
    private String appBaseUrl;

    public GroupController(GroupService groupService) {
        this.groupService = groupService;
    }

    /** GET /groups/member — all groups the caller is part of */
    @GetMapping("/member")
    public List<GroupDetailDTO> myGroups(
            @RequestHeader("X-User-Id") String userId,
            @RequestHeader("X-User-Name") String displayName,
            @RequestHeader("X-User-Email") String email) {
        return groupService.myGroups(userId, displayName, email);
    }

    /** GET /groups/{id} — full group detail */
    @GetMapping("/{id}")
    public GroupDetailDTO getGroup(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        return groupService.getGroupDetail(id, userId);
    }

    /** POST /groups — create a new group */
    @PostMapping
    public GroupDetailDTO createGroup(
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId,
            @RequestHeader("X-User-Name") String displayName,
            @RequestHeader("X-User-Email") String email) {
        String name = body.getOrDefault("name", "").trim();
        if (name.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Group name is required");
        return groupService.createGroup(name, userId, displayName, email);
    }

    /** PUT /groups/{id}/name — rename group */
    @PutMapping("/{id}/name")
    public GroupDetailDTO renameGroup(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId) {
        String name = body.getOrDefault("name", "").trim();
        if (name.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Group name is required");
        return groupService.renameGroup(id, name, userId);
    }

    /** DELETE /groups/{id} — soft-delete group */
    @DeleteMapping("/{id}")
    public void deleteGroup(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        groupService.deleteGroup(id, userId);
    }

    /** POST /groups/{id}/members/{targetUserId}/promote — make admin */
    @PostMapping("/{id}/members/{targetUserId}/promote")
    public GroupMember promoteToAdmin(
            @PathVariable Long id,
            @PathVariable String targetUserId,
            @RequestHeader("X-User-Id") String userId) {
        return groupService.promoteToAdmin(id, targetUserId, userId);
    }

    /** DELETE /groups/{id}/members/{targetUserId} — remove member */
    @DeleteMapping("/{id}/members/{targetUserId}")
    public void removeMember(
            @PathVariable Long id,
            @PathVariable String targetUserId,
            @RequestHeader("X-User-Id") String userId) {
        groupService.removeMember(id, targetUserId, userId);
    }

    /** POST /groups/{id}/invitations — invite by email */
    @PostMapping("/{id}/invitations")
    public GroupInvitation invite(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId,
            @RequestHeader("X-User-Name") String displayName) {
        String email = body.getOrDefault("email", "").trim();
        if (email.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Email is required");
        return groupService.invite(id, email, userId, displayName, appBaseUrl);
    }

    /** DELETE /groups/{id}/invitations/{invitationId} — cancel invite */
    @DeleteMapping("/{id}/invitations/{invitationId}")
    public void cancelInvite(
            @PathVariable Long id,
            @PathVariable Long invitationId,
            @RequestHeader("X-User-Id") String userId) {
        groupService.cancelInvite(id, invitationId, userId);
    }
}
