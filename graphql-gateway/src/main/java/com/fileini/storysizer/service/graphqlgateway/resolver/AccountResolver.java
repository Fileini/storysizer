package com.fileini.storysizer.service.graphqlgateway.resolver;

import com.fileini.storysizer.service.graphqlgateway.model.Estimation;
import com.fileini.storysizer.service.graphqlgateway.model.Story;
import com.fileini.storysizer.service.graphqlgateway.model.UserData;
import graphql.kickstart.tools.GraphQLMutationResolver;
import graphql.kickstart.tools.GraphQLQueryResolver;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;
import java.util.Map;

@Component
public class AccountResolver implements GraphQLQueryResolver, GraphQLMutationResolver {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String baseUrlStory = "http://story-service.service-prod.svc.cluster.local:8080/stories";
    private final String baseUrlEstimation = "http://estimation-service.service-prod.svc.cluster.local:8080/estimations";
    private final String keycloakAdminBaseUrl = envOrDefault("KEYCLOAK_ADMIN_BASE_URL", "https://keycloak.admin.cluster.local.com");
    private final String keycloakRealm = envOrDefault("KEYCLOAK_REALM", "storysizer");
    private final String keycloakAdminRealm = envOrDefault("KEYCLOAK_ADMIN_REALM", "master");
    private final String keycloakAdminClientId = envOrDefault("KEYCLOAK_ADMIN_CLIENT_ID", "admin-cli");
    private final String keycloakGoogleProviderAlias = envOrDefault("KEYCLOAK_GOOGLE_PROVIDER_ALIAS", "google");
    private final String googleRevokeEndpoint = envOrDefault("GOOGLE_TOKEN_REVOKE_URL", "https://oauth2.googleapis.com/revoke");

    /** Query: exportMyData — restituisce tutte le storie e stime dell'utente corrente */
    public UserData exportMyData() {
        String owner = currentOwner();
        if (owner == null) return null;

        String urlStories = UriComponentsBuilder.fromUriString(baseUrlStory + "/owner")
                .pathSegment(owner).toUriString();
        ResponseEntity<List<Story>> storiesResponse = restTemplate.exchange(
                urlStories, HttpMethod.GET, null,
                new ParameterizedTypeReference<List<Story>>() {}
        );

        String urlEstimations = UriComponentsBuilder.fromUriString(baseUrlEstimation + "/owner/{owner}")
                .buildAndExpand(owner).toUriString();
        ResponseEntity<List<Estimation>> estimationsResponse = restTemplate.exchange(
                urlEstimations, HttpMethod.GET, null,
                new ParameterizedTypeReference<List<Estimation>>() {}
        );

        UserData userData = new UserData();
        userData.setStories(storiesResponse.getBody() != null ? storiesResponse.getBody() : List.of());
        userData.setEstimations(estimationsResponse.getBody() != null ? estimationsResponse.getBody() : List.of());
        return userData;
    }

    /** Mutation: deleteMyAccount — cancella tutte le storie e stime dell'utente, poi restituisce true */
    public Boolean deleteMyAccount() {
        String owner = currentOwner();
        String userId = currentUserId();
        String userAccessToken = currentUserAccessToken();

        if (owner == null || userId == null) return false;

        // 1) Revoca autorizzazione federata Google quando disponibile (best effort)
        revokeGoogleToken(userAccessToken);

        // 2) Elimina collegamento federato Google e utente da Keycloak (strict)
        String adminToken = getKeycloakAdminAccessToken();
        unlinkFederatedIdentity(adminToken, userId);
        deleteKeycloakUser(adminToken, userId);

        // 3) Elimina tutti i dati applicativi (stories + estimations)
        deleteApplicationData(owner);

        return true;
        }

        private void deleteApplicationData(String owner) {

        // Recupera tutte le storie dell'owner
        String urlStories = UriComponentsBuilder.fromUriString(baseUrlStory + "/owner")
                .pathSegment(owner).toUriString();
        ResponseEntity<List<Map<String, Object>>> storiesResponse = restTemplate.exchange(
                urlStories, HttpMethod.GET, null,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );

        List<Map<String, Object>> stories = storiesResponse.getBody();
        if (stories != null) {
            for (Map<String, Object> story : stories) {
                Object storyId = story.get("id");
                if (storyId == null) continue;

                // Cancella le stime associate a questa storia
                String urlDeleteEstimations = UriComponentsBuilder
                        .fromUriString(baseUrlEstimation + "/story")
                        .pathSegment(String.valueOf(storyId))
                        .queryParam("owner", owner)
                        .toUriString();
                try {
                    restTemplate.delete(urlDeleteEstimations);
                } catch (Exception ignored) {
                    // Prosegui anche se alcune stime non esistono
                }

                // Cancella la storia
                try {
                    restTemplate.delete(baseUrlStory + "/" + storyId);
                } catch (Exception ignored) {
                    // Prosegui con le altre storie
                }
            }
        }
    }

    private void revokeGoogleToken(String userAccessToken) {
        if (userAccessToken == null || userAccessToken.isBlank()) return;

        String brokerTokenUrl = UriComponentsBuilder
                .fromUriString(keycloakAdminBaseUrl + "/realms/{realm}/broker/{provider}/token")
                .buildAndExpand(keycloakRealm, keycloakGoogleProviderAlias)
                .toUriString();

        HttpHeaders brokerHeaders = new HttpHeaders();
        brokerHeaders.setBearerAuth(userAccessToken);

        try {
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                    brokerTokenUrl,
                    HttpMethod.GET,
                    new HttpEntity<>(brokerHeaders),
                    new ParameterizedTypeReference<Map<String, Object>>() {}
            );

            Map<String, Object> tokenBody = response.getBody();
            if (tokenBody == null) return;

            Object refreshToken = tokenBody.get("refresh_token");
            Object accessToken = tokenBody.get("access_token");

            String tokenToRevoke = refreshToken != null ? String.valueOf(refreshToken)
                    : accessToken != null ? String.valueOf(accessToken)
                    : null;
            if (tokenToRevoke == null || tokenToRevoke.isBlank()) return;

            MultiValueMap<String, String> revokeBody = new LinkedMultiValueMap<>();
            revokeBody.add("token", tokenToRevoke);

            HttpHeaders revokeHeaders = new HttpHeaders();
            revokeHeaders.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            restTemplate.postForEntity(
                    googleRevokeEndpoint,
                    new HttpEntity<>(revokeBody, revokeHeaders),
                    String.class
            );
        } catch (Exception ignored) {
            // Best effort: continuiamo comunque con la cancellazione account
        }
    }

    private String getKeycloakAdminAccessToken() {
        String adminUser = requireEnv("KEYCLOAK_ADMIN_USER");
        String adminPassword = requireEnv("KEYCLOAK_ADMIN_PASSWORD");

        String tokenUrl = UriComponentsBuilder
                .fromUriString(keycloakAdminBaseUrl + "/realms/{realm}/protocol/openid-connect/token")
                .buildAndExpand(keycloakAdminRealm)
                .toUriString();

        MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
        form.add("grant_type", "password");
        form.add("client_id", keycloakAdminClientId);
        form.add("username", adminUser);
        form.add("password", adminPassword);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                tokenUrl,
                HttpMethod.POST,
                new HttpEntity<>(form, headers),
                new ParameterizedTypeReference<Map<String, Object>>() {}
        );

        Map<String, Object> body = response.getBody();
        if (body == null || body.get("access_token") == null) {
            throw new IllegalStateException("Unable to obtain Keycloak admin token");
        }
        return String.valueOf(body.get("access_token"));
    }

    private void unlinkFederatedIdentity(String adminToken, String userId) {
        String unlinkUrl = UriComponentsBuilder
                .fromUriString(keycloakAdminBaseUrl + "/admin/realms/{realm}/users/{userId}/federated-identity/{provider}")
                .buildAndExpand(keycloakRealm, userId, keycloakGoogleProviderAlias)
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(adminToken);

        try {
            restTemplate.exchange(unlinkUrl, HttpMethod.DELETE, new HttpEntity<>(headers), Void.class);
        } catch (Exception ignored) {
            // Se non c'era link federato, proseguiamo
        }
    }

    private void deleteKeycloakUser(String adminToken, String userId) {
        String deleteUrl = UriComponentsBuilder
                .fromUriString(keycloakAdminBaseUrl + "/admin/realms/{realm}/users/{userId}")
                .buildAndExpand(keycloakRealm, userId)
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(adminToken);

        restTemplate.exchange(deleteUrl, HttpMethod.DELETE, new HttpEntity<>(headers), Void.class);
    }

    private String currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) return null;

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            return jwt.getSubject();
        } else if (principal instanceof OidcUser oidc) {
            return oidc.getSubject();
        }
        return null;
    }

    private String currentUserAccessToken() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) return null;

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            return jwt.getTokenValue();
        }
        return null;
    }

    private String currentOwner() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) return null;

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            return jwt.getClaimAsString("preferred_username");
        } else if (principal instanceof OidcUser oidc) {
            return oidc.getPreferredUsername();
        }
        return null;
    }

    private static String requireEnv(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Missing required environment variable: " + key);
        }
        return value;
    }

    private static String envOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value == null || value.isBlank()) ? defaultValue : value;
    }
}
