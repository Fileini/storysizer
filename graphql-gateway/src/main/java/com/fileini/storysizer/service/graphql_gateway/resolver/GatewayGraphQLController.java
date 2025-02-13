package com.fileini.storysizer.service.graphql_gateway.resolver;

import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Controller
public class GatewayGraphQLController {

    private final RestTemplate restTemplate = new RestTemplate();

    @QueryMapping
    public List<Map<String, Object>> stories() {
        String url = "http://story-service:8080/stories";
        return restTemplate.getForObject(url, List.class);
    }

    @QueryMapping
    public List<Map<String, Object>> estimations() {
        String url = "http://estimation-service:8081/estimations";
        return restTemplate.getForObject(url, List.class);
    }
}
