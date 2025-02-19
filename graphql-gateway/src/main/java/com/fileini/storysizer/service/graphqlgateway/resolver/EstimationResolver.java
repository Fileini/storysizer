package com.fileini.storysizer.service.graphqlgateway.resolver;

import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;
import java.util.Map;

@Controller
public class EstimationResolver {

    private final RestTemplate restTemplate = new RestTemplate();


    @QueryMapping
    public List<Map<String, Object>> estimations() {
        String url = "http://estimation-service:8081/estimations";
        return restTemplate.getForObject(url, List.class);
    }


    @SchemaMapping(typeName = "Estimation", field = "story")
    public Map<String, Object> getStory(Map<String, Object> estimation) {
        Long storyId = (Long) estimation.get("story");

        if (storyId == null) {
            return null;
        }

        String url = UriComponentsBuilder.fromUriString("http://story-service.service-prod.svc.cluster.local:8080/stories/" + storyId)
                .toUriString();

        return restTemplate.getForObject(url, Map.class);
    }
}
