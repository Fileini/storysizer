package com.fileini.storysizer.service.graphqlgateway.resolver;

import graphql.kickstart.tools.GraphQLResolver;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;

@Component
public class EstimationFieldResolver implements GraphQLResolver<Map<String, Object>> {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlStory = "http://story-service.service-prod.svc.cluster.local:8080/stories";

    // Field resolver per: Estimation.story : Story
    public Map<String, Object> story(Map<String, Object> estimation) {
        if (estimation == null) return null;
        Object storyId = estimation.get("storyId");
        if (storyId == null) return null;

        String url = UriComponentsBuilder.fromUriString(baseUrlStory + "/" + storyId).toUriString();
        return restTemplate.getForObject(url, Map.class);
    }
}