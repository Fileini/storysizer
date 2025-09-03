package com.fileini.storysizer.service.graphqlgateway.resolver;

import com.coxautodev.graphql.tools.GraphQLMutationResolver;
import com.coxautodev.graphql.tools.GraphQLQueryResolver;
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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class StoryResolver implements GraphQLQueryResolver, GraphQLMutationResolver {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlStory = "http://story-service.service-prod.svc.cluster.local:8080/stories";
    private final String baseUrlEstimation = "http://estimation-service.service-prod.svc.cluster.local:8080/estimations";

    /** Query: stories */
    public List<Map<String, Object>> stories() {
        String owner = currentOwner();
        if (owner == null) return null;

        String url = UriComponentsBuilder.fromUriString(baseUrlStory + "/owner")
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

    /** Mutation: createStory */
    public Map<String, Object> createStory(String name) {
        String owner = currentOwner();
        if (owner == null) return null;

        Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("owner", owner);

        return restTemplate.postForObject(baseUrlStory, payload, Map.class);
    }

    /** Mutation: deleteStory */
    public Boolean deleteStory(String id) {
        String owner = currentOwner();
        if (owner == null) return null;

        String urlGet = UriComponentsBuilder.fromUriString(baseUrlStory + "/owner")
                .pathSegment(owner)
                .queryParam("id", id)
                .toUriString();

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                urlGet,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );

        List<Map<String, Object>> story = response.getBody();
        if (story == null || story.isEmpty()) return false;

        // verifica ownership
        if (!owner.equals(story.get(0).get("owner"))) return false;

        // cascade delete Estimation
        String urlDeleteEstimations = UriComponentsBuilder.fromUriString(baseUrlEstimation + "/story")
                .pathSegment(id)
                .queryParam("owner", owner)
                .toUriString();
        restTemplate.delete(urlDeleteEstimations);

        // delete story
        String urlDelete = baseUrlStory + "/" + id;
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
