package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class GraphiQLController {

    @GetMapping("/graphiql")
    public String graphiql(Model model, Authentication authentication) {
        String token = "";
        if (authentication != null && authentication.getPrincipal() instanceof Jwt) {
            token = ((Jwt) authentication.getPrincipal()).getTokenValue();
        }
        model.addAttribute("authToken", token);
        return "graphiql";
    }
}
