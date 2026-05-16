package com.fileini.storysizer.service.group.mail;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Component
public class ResendMailClient {

    private static final String RESEND_API = "https://api.resend.com/emails";

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${storysizer.mail.resend-api-key}")
    private String apiKey;

    @Value("${storysizer.mail.from}")
    private String from;

    /**
     * Sends a group invitation email via Resend HTTP API.
     * Throws RestClientException on failure so callers can roll back.
     */
    public void sendInvite(String toEmail, String inviterName, String groupName, String joinLink) {
        String html = MailTemplates.inviteHtml(inviterName, groupName, joinLink);
        String text = MailTemplates.inviteText(inviterName, groupName, joinLink);
        send(toEmail,
             inviterName + " invited you to join a StorySizer group",
             html, text);
    }

    private void send(String to, String subject, String html, String text) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(apiKey);
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = Map.of(
            "from", from,
            "to", List.of(to),
            "subject", subject,
            "html", html,
            "text", text
        );

        restTemplate.postForEntity(RESEND_API, new HttpEntity<>(body, headers), Map.class);
    }
}
