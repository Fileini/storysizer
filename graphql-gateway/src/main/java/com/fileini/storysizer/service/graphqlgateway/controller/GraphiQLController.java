package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class GraphiQLController {

    @GetMapping("/graphiql")
    public String graphiql(Model model, Authentication authentication) {
        String token = "";
        if (authentication != null) {
            Object principal = authentication.getPrincipal();
            if (principal instanceof Jwt) {
                token = ((Jwt) principal).getTokenValue();
            } else if (principal instanceof OidcUser) {
                // Per OidcUser, il token JWT si trova nell'id token
                token = ((OidcUser) principal).getIdToken().getTokenValue();
            }
        }
        model.addAttribute("authToken", token);
        return "graphiql";
    }
}
