package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.annotation.RegisteredOAuth2AuthorizedClient;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class GraphiQLController {

    @GetMapping("/graphiql")
    public String graphiql(Model model, 
                           Authentication authentication,
                           @RegisteredOAuth2AuthorizedClient("keycloak") OAuth2AuthorizedClient authorizedClient) {
        String token = "";
        if (authorizedClient != null) {
            token = authorizedClient.getAccessToken().getTokenValue();
        }
        model.addAttribute("authToken", token);
        return "graphiql";
    }
}
