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
import org.springframework.stereotype.Controller;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class StoryResolver {


    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlstory = "http://story-service.service-prod.svc.cluster.local:8080/stories/owner";

    @QueryMapping
    public List<Map<String, Object>> stories() {
      
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String owner = "";
           if (authentication.getPrincipal() instanceof OidcUser){
               owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
           }else throw new RuntimeException("Non Autorizzato");
               
    
            // Costruisci l'URL con il parametro di query per il filtraggio
        String url = UriComponentsBuilder.fromUriString(baseUrlstory)
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
            if (authentication.getPrincipal() instanceof OidcUser){
                owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
            }else throw new RuntimeException("Non Autorizzato");
                
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
           if (authentication.getPrincipal() instanceof OidcUser){
               owner = ((OidcUser) authentication.getPrincipal()).getPreferredUsername();
           }else throw new RuntimeException("Non Autorizzato");
               
    
    String urlGet = UriComponentsBuilder.fromUriString(baseUrlstory)
    .queryParam("owner", owner)
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
        throw new RuntimeException("Story non trovata");
    }
    
    // Verifica che la story appartenga all'utente autenticato
    if (!owner.equals(story.get(0).get("owner"))) {
        throw new RuntimeException("Non autorizzato a cancellare questa story");
    }
    
    // Se la verifica ha successo, inoltra la richiesta di cancellazione al microservizio
    String urlDelete = baseUrlstory + id;
    restTemplate.delete(urlDelete);
    
    return true;

    }
}
