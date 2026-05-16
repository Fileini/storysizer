package com.fileini.storysizer.service.graphqlgateway.resolver;

import graphql.kickstart.tools.GraphQLMutationResolver;
import graphql.kickstart.tools.GraphQLQueryResolver;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/**
 * GraphQL resolver for all group-related queries and mutations.
 * Delegates to group-service via REST (cluster-internal).
 * Passes user context as headers so group-service never touches the JWT directly.
 */
@Component
public class GroupResolver implements GraphQLQueryResolver, GraphQLMutationResolver {

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String BASE = "http://group-service.service-prod.svc.cluster.local:8080";

    // ─── Queries ─────────────────────────────────────────────────────────────

    public List<Map<String, Object>> myGroups() {
        HttpEntity<Void> req = new HttpEntity<>(userHeaders());
        ResponseEntity<List<Map<String, Object>>> resp = restTemplate.exchange(
            BASE + "/groups/member", HttpMethod.GET, req,
            new ParameterizedTypeReference<>() {});
        return resp.getBody();
    }

    public Map<String, Object> group(String id) {
        HttpEntity<Void> req = new HttpEntity<>(userHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + id, HttpMethod.GET, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public List<Map<String, Object>> groupEstimations(String groupId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        ResponseEntity<List<Map<String, Object>>> resp = restTemplate.exchange(
            BASE + "/group-estimations/group/" + groupId, HttpMethod.GET, req,
            new ParameterizedTypeReference<>() {});
        return resp.getBody();
    }

    public int myPendingGroupEstimationsCount() {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        Map<String, Object> resp = restTemplate.exchange(
            BASE + "/group-estimations/user/pending-count", HttpMethod.GET, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
        if (resp == null) return 0;
        Object count = resp.get("count");
        return count == null ? 0 : ((Number) count).intValue();
    }

    public List<Map<String, Object>> groupEstimationFeed() {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        ResponseEntity<List<Map<String, Object>>> resp = restTemplate.exchange(
            BASE + "/group-estimations/user/feed", HttpMethod.GET, req,
            new ParameterizedTypeReference<>() {});
        return resp.getBody();
    }

    public Map<String, Object> myVote(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/my-vote",
            HttpMethod.GET, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public Map<String, Object> groupEstimationDashboard(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/dashboard",
            HttpMethod.GET, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    // ─── Group mutations ─────────────────────────────────────────────────────

    public Map<String, Object> createGroup(String name) {
        return post("/groups", Map.of("name", name), userHeaders());
    }

    public Map<String, Object> renameGroup(String groupId, String name) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("name", name), userHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + groupId + "/name", HttpMethod.PUT, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public Boolean deleteGroup(String groupId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(BASE + "/groups/" + groupId, HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public Map<String, Object> inviteToGroup(String groupId, String email) {
        return post("/groups/" + groupId + "/invitations", Map.of("email", email), userHeaders());
    }

    public Boolean cancelGroupInvite(String groupId, String invitationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/groups/" + groupId + "/invitations/" + invitationId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public Map<String, Object> promoteGroupMember(String groupId, String targetUserId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + groupId + "/members/" + targetUserId + "/promote",
            HttpMethod.POST, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public Boolean removeGroupMember(String groupId, String targetUserId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/groups/" + groupId + "/members/" + targetUserId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    // ─── Group estimation mutations ───────────────────────────────────────────

    public Map<String, Object> createGroupEstimation(String groupId, String title) {
        return post("/group-estimations", Map.of("groupId", groupId, "title", title), idOnlyHeaders());
    }

    public Map<String, Object> submitGroupEstimationVote(String groupEstimationId,
            int complexity, int reach, int dimensions, int risk, int interaction) {
        Map<String, Object> body = Map.of(
            "complexity", complexity, "reach", reach, "dimensions", dimensions,
            "risk", risk, "interaction", interaction);
        HttpEntity<Map<String, Object>> req = new HttpEntity<>(body, idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/vote",
            HttpMethod.POST, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public Boolean restartGroupEstimation(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/restart",
            HttpMethod.POST, req, Void.class);
        return true;
    }

    public Map<String, Object> renameGroupEstimation(String groupEstimationId, String title) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("title", title), idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/title",
            HttpMethod.PUT, req,
            new ParameterizedTypeReference<Map<String, Object>>() {}).getBody();
    }

    public Boolean deleteGroupEstimation(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public Map<String, Object> acceptGroupInvite(String token) {
        return post("/invitations/accept", Map.of("token", token), userHeaders());
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /** Headers with all three user context fields (for mutations that need email/name too) */
    private HttpHeaders userHeaders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);

        String userId, displayName, email;
        Object principal = auth.getPrincipal();
        if (principal instanceof Jwt jwt) {
            userId      = jwt.getSubject();
            displayName = jwt.getClaimAsString("preferred_username");
            email       = jwt.getClaimAsString("email");
        } else if (principal instanceof OidcUser oidc) {
            userId      = oidc.getSubject();
            displayName = oidc.getPreferredUsername();
            email       = oidc.getEmail();
        } else {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }

        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-User-Id",    userId      != null ? userId      : "");
        h.set("X-User-Name",  displayName != null ? displayName : "");
        h.set("X-User-Email", email       != null ? email       : "");
        return h;
    }

    /** Headers with only X-User-Id (for operations that don't need email/name) */
    private HttpHeaders idOnlyHeaders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);

        String userId;
        Object principal = auth.getPrincipal();
        if (principal instanceof Jwt jwt) {
            userId = jwt.getSubject();
        } else if (principal instanceof OidcUser oidc) {
            userId = oidc.getSubject();
        } else {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }

        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-User-Id", userId != null ? userId : "");
        return h;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> post(String path, Map<String, ?> body, HttpHeaders headers) {
        HttpEntity<Map<String, ?>> req = new HttpEntity<>(body, headers);
        return (Map<String, Object>) restTemplate.postForObject(BASE + path, req, Map.class);
    }
}
