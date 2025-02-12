package com.fileini.storysizer.service.graphql_gateway.resolver;

import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;

@Controller
public class EstimationResolver {

    private final RestTemplate restTemplate = new RestTemplate();

    @SchemaMapping(typeName = "Estimation", field = "reach")
    public Story getStory(Estimation estimation) {
        return restTemplate.getForObject(
            "http://story-service:8080/stories/" + estimation.getStoryId(),
            Story.class
        );
    }
}
