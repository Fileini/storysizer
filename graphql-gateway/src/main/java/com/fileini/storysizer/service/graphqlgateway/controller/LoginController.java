package com.fileini.storysizer.service.graphqlgateway.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class LoginController {

    @GetMapping("/custom-login")
    public String customLogin() {
        return "custom-login"; // corrisponde a custom-login.html in src/main/resources/templates
    }
}
