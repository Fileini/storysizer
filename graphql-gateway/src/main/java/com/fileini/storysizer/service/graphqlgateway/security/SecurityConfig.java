package com.fileini.storysizer.service.graphql_gateway.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            // Consenti l'accesso all'interfaccia GraphiQL e alle eventuali risorse statiche collegate
            .requestMatchers("/graphiql/**", "/vendor/**", "/css/**", "/js/**").permitAll()
            // Richiedi l'autenticazione per l'endpoint GraphQL
            .requestMatchers("/graphql").authenticated()
            // Per tutte le altre richieste, concedi l'accesso
            .anyRequest().permitAll()
        )
        .oauth2ResourceServer(oauth2 -> oauth2.jwt());

    return http.build();
}


}
