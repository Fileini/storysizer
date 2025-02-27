package com.fileini.storysizer.service.graphqlgateway.resolver;

import org.springframework.core.ParameterizedTypeReference;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.MutationMapping;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class EstimationResolver {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlestimation = "http://estimation-service.service-prod.svc.cluster.local:8080/estimations";
    private final String baseUrlstory = "http://story-service.service-prod.svc.cluster.local:8080/stories";


    @QueryMapping
    public List<Map<String, Object>> estimations() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String owner = "";
           if (authentication.getPrincipal() instanceof OidcUser){
               owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
           }else return null;
               
    
            // Costruisci l'URL con il parametro di query per il filtraggio
        String url = UriComponentsBuilder.fromUriString(baseUrlestimation + "/owner")
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


    @SchemaMapping(typeName = "Estimation", field = "story")
    public Map<String, Object> getStory(Map<String, Object> estimation) {
        Integer storyId = (Integer) estimation.get("storyId");

        if (storyId == null) {
            return null;
        }

        String url = UriComponentsBuilder.fromUriString("http://story-service.service-prod.svc.cluster.local:8080/stories/" + storyId)
                .toUriString();

        return restTemplate.getForObject(url, Map.class);
    }


    @MutationMapping   
    public Map<String, Object> createEstimation(
        @Argument String name, 
        @Argument Integer complexity,
        @Argument Integer reach,
        @Argument Integer dimension,
        @Argument Integer risk,
        @Argument Integer interaction, 
        @Argument String storyId ) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
         String owner = "";
            if (authentication.getPrincipal() instanceof OidcUser){
                owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
            }else return null;
        
            
        String urlGet = UriComponentsBuilder.fromUriString(baseUrlstory + "/owner")
        .pathSegment(owner)
        .queryParam("storyId", storyId)
        .toUriString();

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                    urlGet,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Map<String, Object>>>() {}
            );


        List<Map<String, Object>> story = response.getBody();
        
        if (story.isEmpty()) {
            return null;
        }
        
        // Verifica che la story appartenga all'utente autenticato
        if (!owner.equals(story.get(0).get("owner"))) {
            return null;
        }
                
        Map<String, Object> payload = new HashMap<>();
        payload.put("name", name);
        payload.put("owner", story.get(0).get("owner"));
        payload.put("complexity", complexity);
        payload.put("reach", reach);
        payload.put("storyId", story.get(0).get("id"));
        payload.put("dimensions", dimension);
        payload.put("risk", risk);
        payload.put("interaction", interaction);

        Map<String, Object> createdStory = restTemplate.postForObject(baseUrlestimation, payload, Map.class);

        return createdStory;
    }

    @MutationMapping
    public Boolean deleteEstimation(@Argument String id) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    String owner = "";
           if (authentication.getPrincipal() instanceof OidcUser){
               owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
           }else return false;
               
    
    String urlGet = UriComponentsBuilder.fromUriString(baseUrlestimation + "/owner")
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
    
    if (estimation.isEmpty()) {
        return false;
    }
    
    // Verifica che la story appartenga all'utente autenticato
    if (!owner.equals(estimation.get(0).get("owner"))) {
        return false;
    }
    
    // Se la verifica ha successo, inoltra la richiesta di cancellazione al microservizio
    String urlDelete = baseUrlestimation +'/'+ id;
    restTemplate.delete(urlDelete);


    return true;

    }


}
