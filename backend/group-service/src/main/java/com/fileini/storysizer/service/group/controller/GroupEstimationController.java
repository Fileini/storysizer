package com.fileini.storysizer.service.group.controller;

import com.fileini.storysizer.service.group.dto.GroupEstimationDashboardDTO;
import com.fileini.storysizer.service.group.model.GroupEstimation;
import com.fileini.storysizer.service.group.model.GroupEstimationVote;
import com.fileini.storysizer.service.group.service.GroupEstimationService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/group-estimations")
public class GroupEstimationController {

    private final GroupEstimationService estimationService;

    public GroupEstimationController(GroupEstimationService estimationService) {
        this.estimationService = estimationService;
    }

    /** GET /group-estimations/group/{groupId} — all estimations for a group */
    @GetMapping("/group/{groupId}")
    public List<GroupEstimation> getByGroup(@PathVariable Long groupId) {
        return estimationService.getByGroup(groupId);
    }

    /** GET /group-estimations/user/feed — feed (pending first, then submitted) */
    @GetMapping("/user/feed")
    public List<GroupEstimation> getFeed(@RequestHeader("X-User-Id") String userId) {
        return estimationService.getFeedForUser(userId);
    }

    /** GET /group-estimations/user/pending-count — badge count */
    @GetMapping("/user/pending-count")
    public Map<String, Long> getPendingCount(@RequestHeader("X-User-Id") String userId) {
        return Map.of("count", estimationService.countPendingForUser(userId));
    }

    /** GET /group-estimations/{id}/my-vote — current user's vote status */
    @GetMapping("/{id}/my-vote")
    public GroupEstimationVote getMyVote(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        return estimationService.getMyVote(id, userId);
    }

    /** GET /group-estimations/{id}/dashboard */
    @GetMapping("/{id}/dashboard")
    public GroupEstimationDashboardDTO getDashboard(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        return estimationService.getDashboard(id, userId);
    }

    /** POST /group-estimations — create new group estimation */
    @PostMapping
    public GroupEstimation create(
            @RequestBody Map<String, Object> body,
            @RequestHeader("X-User-Id") String userId) {
        Long groupId = Long.valueOf(body.get("groupId").toString());
        String title = body.getOrDefault("title", "").toString().trim();
        if (title.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Title is required");
        return estimationService.createGroupEstimation(groupId, title, userId);
    }

    /** PUT /group-estimations/{id}/title — rename */
    @PutMapping("/{id}/title")
    public GroupEstimation rename(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @RequestHeader("X-User-Id") String userId) {
        String title = body.getOrDefault("title", "").trim();
        if (title.isEmpty()) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Title is required");
        return estimationService.rename(id, title, userId);
    }

    /** POST /group-estimations/{id}/restart — reset all votes to TO_SIZE */
    @PostMapping("/{id}/restart")
    public void restart(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        estimationService.restart(id, userId);
    }

    /** DELETE /group-estimations/{id} — delete estimation and all votes */
    @DeleteMapping("/{id}")
    public void delete(
            @PathVariable Long id,
            @RequestHeader("X-User-Id") String userId) {
        estimationService.delete(id, userId);
    }

    /** POST /group-estimations/{id}/vote — submit a vote */
    @PostMapping("/{id}/vote")
    public GroupEstimationVote submitVote(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body,
            @RequestHeader("X-User-Id") String userId) {
        int complexity   = intVal(body, "complexity");
        int reach        = intVal(body, "reach");
        int dimensions   = intVal(body, "dimensions");
        int risk         = intVal(body, "risk");
        int interaction  = intVal(body, "interaction");
        return estimationService.submitVote(id, userId, complexity, reach, dimensions, risk, interaction);
    }

    private static int intVal(Map<String, Object> body, String key) {
        Object v = body.get(key);
        if (v == null) throw new org.springframework.web.server.ResponseStatusException(
            org.springframework.http.HttpStatus.BAD_REQUEST, "Missing field: " + key);
        return Integer.parseInt(v.toString());
    }
}
