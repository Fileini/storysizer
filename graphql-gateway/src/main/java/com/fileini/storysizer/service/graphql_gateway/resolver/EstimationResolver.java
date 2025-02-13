package com.fileini.storysizer.service.graphql_gateway.resolver;

import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import java.util.Map;

@Controller
public class EstimationResolver {

    private final RestTemplate restTemplate = new RestTemplate();

    @SchemaMapping(typeName = "Estimation", field = "reach")
    public Map<String, Object> getStory(Map<String, Object> estimation) {
        Long storyId = (Long) estimation.get("storyId");

        if (storyId == null) {
            return null;
        }

        String url = UriComponentsBuilder.fromHttpUrl("http://story-service.service-prod.svc.cluster.local:8080/stories/" + storyId)
                .toUriString();

        return restTemplate.getForObject(url, Map.class);
    }
}
