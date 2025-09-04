package com.fileini.storysizer.service.graphqlgateway.resolver;

import graphql.kickstart.tools.GraphQLResolver;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import com.fileini.storysizer.service.graphqlgateway.model.Estimation;
import com.fileini.storysizer.service.graphqlgateway.model.Story;

@Component
public class EstimationFieldResolver implements GraphQLResolver<Estimation> {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlStory = "http://story-service.service-prod.svc.cluster.local:8080/stories";

    // Risolve: Estimation.story : Story
    public Story story(Estimation estimation) {
        Object storyId = estimation.get("storyId");
        if (storyId == null) return null;

        String url = UriComponentsBuilder
                .fromUriString(baseUrlStory + "/" + String.valueOf(storyId))
                .toUriString();

        return restTemplate.getForObject(url, Story.class);
    }
}
