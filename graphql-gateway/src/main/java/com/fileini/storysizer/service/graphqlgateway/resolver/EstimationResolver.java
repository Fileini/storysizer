package com.fileini.storysizer.service.graphqlgateway.resolver;


import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import graphql.kickstart.tools.GraphQLMutationResolver;
import graphql.kickstart.tools.GraphQLQueryResolver;
import graphql.kickstart.tools.GraphQLResolver;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class EstimationResolver implements GraphQLQueryResolver, GraphQLMutationResolver  {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlEstimation = "http://estimation-service.service-prod.svc.cluster.local:8080/estimations";
    private final String baseUrlStory = "http://story-service.service-prod.svc.cluster.local:8080/stories";

    /** Query: estimations */
    public List<Map<String, Object>> estimations() {
        String owner = currentOwner();
        if (owner == null) return null;

        String url = UriComponentsBuilder.fromUriString(baseUrlEstimation + "/owner")
                .pathSegment(owner)
                .toUriString();

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );
        return response.getBody();
    }

    /** Field resolver: Estimation.story (ex @SchemaMapping) */
    public Map<String, Object> story(Map<String, Object> estimation) {
        Integer storyId = estimation == null ? null : (Integer) estimation.get("storyId");
        if (storyId == null) return null;

        String url = UriComponentsBuilder.fromUriString(baseUrlStory + "/" + storyId)
                .toUriString();

        return restTemplate.getForObject(url, Map.class);
    }

    /** Mutation: createEstimation */
    public Map<String, Object> createEstimation(
            String name,
            Integer complexity,
            Integer reach,
            Integer dimension,
            Integer risk,
            Integer interaction,
            String storyId
    ) {
        String owner = currentOwner();
        if (owner == null) return null;

        String urlGet = UriComponentsBuilder.fromUriString(baseUrlStory + "/owner")
                .pathSegment(owner)
                .queryParam("id", storyId)
                .toUriString();

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                urlGet,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );

        List<Map<String, Object>> story = response.getBody();
        if (story == null || story.isEmpty()) return null;

        // verifica ownership
        if (!owner.equals(story.get(0).get("owner"))) return null;

        Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("owner", story.get(0).get("owner"));
        payload.put("complexity", complexity);
        payload.put("reach", reach);
        payload.put("storyId", story.get(0).get("id"));
        payload.put("dimensions", dimension);
        payload.put("risk", risk);
        payload.put("interaction", interaction);

        return restTemplate.postForObject(baseUrlEstimation, payload, Map.class);
    }

    /** Mutation: deleteEstimation */
    public Boolean deleteEstimation(String id) {
        String owner = currentOwner();
        if (owner == null) return null;

        String urlGet = UriComponentsBuilder.fromUriString(baseUrlEstimation + "/owner")
                .pathSegment(owner)
                .queryParam("id", id)
                .toUriString();

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                urlGet,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );

        List<Map<String, Object>> estimation = response.getBody();
        if (estimation == null || estimation.isEmpty()) return false;

        if (!owner.equals(estimation.get(0).get("owner"))) return false;

        String urlDelete = baseUrlEstimation + "/" + id;
        restTemplate.delete(urlDelete);
        return true;
    }

    /** Helper: recupera l'owner dall'Authentication */
    private String currentOwner() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) return null;

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            return jwt.getClaimAsString("preferred_username");
        } else if (principal instanceof OidcUser oidc) {
            return oidc.getPreferredUsername();
        }
        return null;
    }
}
