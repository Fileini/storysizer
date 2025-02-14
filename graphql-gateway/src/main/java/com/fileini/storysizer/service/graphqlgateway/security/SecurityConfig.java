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
                // Escludi dalla sicurezza la pagina di login e altri endpoint statici
                .requestMatchers("/custom-login", "/error", "/css/**", "/js/**", "/vendor/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .loginPage("/custom-login")
                .permitAll() // Assicurati che il login sia esente
            )
            .logout(logout -> logout.permitAll())
            // Disabilita CSRF solo se necessario (attenzione in produzione)
            .csrf(csrf -> csrf.disable());

        return http.build();
    }
}
