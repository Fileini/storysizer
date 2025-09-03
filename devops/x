package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.annotation.RegisteredOAuth2AuthorizedClient;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Controller
public class GraphiQLController {

    private static final Logger logger = LoggerFactory.getLogger(GraphiQLController.class);

    @GetMapping("/graphiql")
    public String graphiql(Model model,
                           @RegisteredOAuth2AuthorizedClient("keycloak") OAuth2AuthorizedClient authorizedClient) {
        String token = "";
        if (authorizedClient != null && authorizedClient.getAccessToken() != null) {
            token = authorizedClient.getAccessToken().getTokenValue();
            logger.info("Access Token: {}", token);
        } else {
            logger.warn("Authorized client o token mancante!");
        }
        model.addAttribute("authToken", token);
        return "graphiql";
    }
}
