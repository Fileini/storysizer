package com.fileini.storysizer.service.graphqlgateway.security;

import java.util.Arrays;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Abilito il supporto CORS
            .cors(Customizer.withDefaults())
            .authorizeHttpRequests(auth -> auth
                // Consento tutte le richieste OPTIONS (necessarie per il preflight)
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // Escludo dalla sicurezza altri endpoint statici o di login
                .requestMatchers("/custom-login", "/error", "/css/**", "/js/**", "/vendor/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .loginPage("/custom-login")
                .defaultSuccessUrl("/graphiql", true)
                .permitAll()
            )
            .logout(logout -> logout.permitAll());
            

        return http.build();
    }

    // Configurazione CORS globale
    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // Specifica l'origine autorizzata; per il testing puoi usare "*" o l'origine esatta del tuo client
        configuration.setAllowedOrigins(Arrays.asList("http://localhost:36145", "https://storysizer.public.cluster.local.com"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With", "Accept"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
