package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class GraphiQLController {

    @GetMapping("/graphiql")
    public String graphiql() {
        // Assicurati di avere un file "graphiql.html" in src/main/resources/templates
        return "graphiql";
    }
}
