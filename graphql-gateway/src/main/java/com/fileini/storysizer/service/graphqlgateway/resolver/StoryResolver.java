package com.fileini.storysizer.service.graphqlgateway.resolver;

import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Controller
public class StoryResolver {

    private final RestTemplate restTemplate = new RestTemplate();

    @MutationMapping
    public Map<String, Object> createStory(@Argument String name) {
        // Estrai l'identificatore dell'utente autenticato da Keycloak
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String owner = "";
        if (authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            owner = jwt.getSubject(); // tipicamente il claim "sub" rappresenta l'identificatore dell'utente
        }
        // Costruisci il payload per il microservizio story-service
        Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("owner", owner);
        
        // Inoltra la richiesta al REST endpoint di story-service
        String url = "http://story-service:8080/stories";
        Map<String, Object> createdStory = restTemplate.postForObject(url, payload, Map.class);
        
        return createdStory;
    }
}
