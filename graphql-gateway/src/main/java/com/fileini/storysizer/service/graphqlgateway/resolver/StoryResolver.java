package com.fileini.storysizer.service.graphqlgateway.resolver;

import org.springframework.core.ParameterizedTypeReference;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class StoryResolver {


    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlstory = "http://story-service.service-prod.svc.cluster.local:8080/stories";
    private final String baseUrlestimation = "http://estimation-service.service-prod.svc.cluster.local:8080/estimations";


    @QueryMapping
    public List<Map<String, Object>> stories() {
      
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String owner = "";
        if (authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            owner = jwt.getClaimAsString("preferred_username");
        } else if (authentication.getPrincipal() instanceof OidcUser) {
            owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
        } else {
            return null;
        }
               
    
            // Costruisci l'URL con il parametro di query per il filtraggio
        String url = UriComponentsBuilder.fromUriString(baseUrlstory + "/owner")
                .pathSegment(owner)
                .toUriString();

        // Effettua la chiamata al microservizio story-service
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );

        return response.getBody();
    }
    

    @MutationMapping
    public Map<String, Object> createStory(@Argument String name) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
         String owner = "";
         if (authentication.getPrincipal() instanceof Jwt) {
            Jwt jwt = (Jwt) authentication.getPrincipal();
            owner = jwt.getClaimAsString("preferred_username");
        } else if (authentication.getPrincipal() instanceof OidcUser) {
            owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
        } else {
            return null;
        }
                
        Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("owner", owner);
        Map<String, Object> createdStory = restTemplate.postForObject(baseUrlstory, payload, Map.class);

        return createdStory;
    }

    
    @MutationMapping
    public Boolean deleteStory(@Argument String id) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    String owner = "";
    if (authentication.getPrincipal() instanceof Jwt) {
        Jwt jwt = (Jwt) authentication.getPrincipal();
        owner = jwt.getClaimAsString("preferred_username");
    } else if (authentication.getPrincipal() instanceof OidcUser) {
        owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
    } else {
        return null;
    }
    
    String urlGet = UriComponentsBuilder.fromUriString(baseUrlstory + "/owner")
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
    
    if (story.isEmpty()) {
        return false;
    }
    
    // Verifica che la story appartenga all'utente autenticato
    if (!owner.equals(story.get(0).get("owner"))) {
        return false;
    }
    
    
    // Cascade delete Estimation
    String urlDeleteEstimations = UriComponentsBuilder.fromUriString(baseUrlestimation + "/story")
    .pathSegment(id)
    .queryParam("owner", owner)
    .toUriString();
    restTemplate.delete(urlDeleteEstimations);

    //delete story
    String urlDelete = baseUrlstory +'/'+ id;
    restTemplate.delete(urlDelete);


    return true;

    }
}
