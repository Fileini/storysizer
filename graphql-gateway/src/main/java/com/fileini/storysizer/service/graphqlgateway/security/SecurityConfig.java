package com.fileini.storysizer.service.graphqlgateway.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                // Consenti l'accesso all'interfaccia GraphiQL e alle eventuali risorse statiche
                .requestMatchers("/graphiql/**", "/vendor/**", "/css/**", "/js/**").permitAll()
                // Richiedi l'autenticazione per tutte le altre richieste
                .anyRequest().authenticated()
            )
            // Abilita OAuth2 Login per il flusso SSO
            .oauth2Login(oauth2 -> oauth2.loginPage("/custom-login"))
            // Configura il resource server per gestire le richieste con token JWT
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());

        return http.build();
    }
}
