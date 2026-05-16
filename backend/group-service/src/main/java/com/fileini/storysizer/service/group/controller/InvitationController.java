package com.fileini.storysizer.service.group.controller;

import com.fileini.storysizer.service.group.dto.GroupDetailDTO;
import com.fileini.storysizer.service.group.service.GroupService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Handles the public invite-acceptance flow.
 * The raw token comes from the email link and is validated via hash.
 */
@RestController
@RequestMapping("/invitations")
public class InvitationController {

    private final GroupService groupService;

    public InvitationController(GroupService groupService) {
        this.groupService = groupService;
    }

    /**
     * POST /invitations/accept
     * Body: { "token": "..." }
     * Headers: X-User-Id, X-User-Name, X-User-Email  (set by gateway from JWT)
     */
    @PostMapping("/accept")
    public GroupDetailDTO accept(
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId,
            @RequestHeader("X-User-Name") String displayName,
            @RequestHeader("X-User-Email") String userEmail) {
        String token = body.getOrDefault("token", "").trim();
        if (token.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Token is required");
        return groupService.acceptInvite(token, userId, displayName, userEmail);
    }
}
