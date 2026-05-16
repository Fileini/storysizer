package com.fileini.storysizer.service.graphqlgateway.resolver;

import com.fileini.storysizer.service.graphqlgateway.model.GroupDetail;
import com.fileini.storysizer.service.graphqlgateway.model.GroupEstimationDashboard;
import com.fileini.storysizer.service.graphqlgateway.model.GroupEstimationItem;
import com.fileini.storysizer.service.graphqlgateway.model.GroupEstimationVote;
import com.fileini.storysizer.service.graphqlgateway.model.GroupInvitation;
import com.fileini.storysizer.service.graphqlgateway.model.GroupMember;

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

    public List<GroupDetail> myGroups() {
        HttpEntity<Void> req = new HttpEntity<>(userHeaders());
        return restTemplate.exchange(
            BASE + "/groups/member", HttpMethod.GET, req,
            new ParameterizedTypeReference<List<GroupDetail>>() {}).getBody();
    }

    public GroupDetail group(String id) {
        HttpEntity<Void> req = new HttpEntity<>(userHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + id, HttpMethod.GET, req, GroupDetail.class).getBody();
    }

    public List<GroupEstimationItem> groupEstimations(String groupId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/group/" + groupId, HttpMethod.GET, req,
            new ParameterizedTypeReference<List<GroupEstimationItem>>() {}).getBody();
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

    public List<GroupEstimationItem> groupEstimationFeed() {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/user/feed", HttpMethod.GET, req,
            new ParameterizedTypeReference<List<GroupEstimationItem>>() {}).getBody();
    }

    public GroupEstimationVote myVote(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/my-vote",
            HttpMethod.GET, req, GroupEstimationVote.class).getBody();
    }

    public GroupEstimationDashboard groupEstimationDashboard(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/dashboard",
            HttpMethod.GET, req, GroupEstimationDashboard.class).getBody();
    }

    // ─── Group mutations ─────────────────────────────────────────────────────

    public GroupDetail createGroup(String name) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("name", name), userHeaders());
        return restTemplate.postForObject(BASE + "/groups", req, GroupDetail.class);
    }

    public GroupDetail renameGroup(String groupId, String name) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("name", name), userHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + groupId + "/name", HttpMethod.PUT, req,
            GroupDetail.class).getBody();
    }

    public Boolean deleteGroup(String groupId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(BASE + "/groups/" + groupId, HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public GroupInvitation inviteToGroup(String groupId, String email) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("email", email), userHeaders());
        return restTemplate.postForObject(
            BASE + "/groups/" + groupId + "/invitations", req, GroupInvitation.class);
    }

    public Boolean cancelGroupInvite(String groupId, String invitationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/groups/" + groupId + "/invitations/" + invitationId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public GroupMember promoteGroupMember(String groupId, String targetUserId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/groups/" + groupId + "/members/" + targetUserId + "/promote",
            HttpMethod.POST, req, GroupMember.class).getBody();
    }

    public Boolean removeGroupMember(String groupId, String targetUserId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/groups/" + groupId + "/members/" + targetUserId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    // ─── Group estimation mutations ───────────────────────────────────────────

    public GroupEstimationItem createGroupEstimation(String groupId, String title) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(
            Map.of("groupId", groupId, "title", title), idOnlyHeaders());
        return restTemplate.postForObject(BASE + "/group-estimations", req, GroupEstimationItem.class);
    }

    public GroupEstimationVote submitGroupEstimationVote(String groupEstimationId,
            int complexity, int reach, int dimensions, int risk, int interaction) {
        Map<String, Object> body = Map.of(
            "complexity", complexity, "reach", reach, "dimensions", dimensions,
            "risk", risk, "interaction", interaction);
        HttpEntity<Map<String, Object>> req = new HttpEntity<>(body, idOnlyHeaders());
        return restTemplate.postForObject(
            BASE + "/group-estimations/" + groupEstimationId + "/vote",
            req, GroupEstimationVote.class);
    }

    public Boolean restartGroupEstimation(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/restart",
            HttpMethod.POST, req, Void.class);
        return true;
    }

    public GroupEstimationItem renameGroupEstimation(String groupEstimationId, String title) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("title", title), idOnlyHeaders());
        return restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId + "/title",
            HttpMethod.PUT, req, GroupEstimationItem.class).getBody();
    }

    public Boolean deleteGroupEstimation(String groupEstimationId) {
        HttpEntity<Void> req = new HttpEntity<>(idOnlyHeaders());
        restTemplate.exchange(
            BASE + "/group-estimations/" + groupEstimationId,
            HttpMethod.DELETE, req, Void.class);
        return true;
    }

    public GroupDetail acceptGroupInvite(String token) {
        HttpEntity<Map<String, String>> req = new HttpEntity<>(Map.of("token", token), userHeaders());
        return restTemplate.postForObject(BASE + "/invitations/accept", req, GroupDetail.class);
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
}
