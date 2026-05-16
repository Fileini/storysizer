package com.fileini.storysizer.service.group.mail;

/** Simple string-based mail templates — no Thymeleaf needed for a single email type. */
public final class MailTemplates {

    private MailTemplates() {}

    public static String inviteHtml(String inviterName, String groupName, String joinLink) {
        String safeInviter = escapeHtml(inviterName);
        String safeGroup   = escapeHtml(groupName);
        String safeLink    = escapeHtml(joinLink);

        return """
            <!DOCTYPE html>
            <html lang="en">
            <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
            <body style="font-family:sans-serif;background:#f5f5f5;padding:32px;">
              <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:12px;padding:32px;">
                <img src="https://app.storysizer.org/assets/logo.png" alt="StorySizer" height="40" style="margin-bottom:24px;">
                <h2 style="margin:0 0 16px;">You've been invited!</h2>
                <p style="color:#444;">
                  <strong>%s</strong> has invited you to join the group
                  <strong>"%s"</strong> on StorySizer.
                </p>
                <a href="%s"
                   style="display:inline-block;margin-top:24px;padding:12px 28px;
                          background:#1976D2;color:#fff;border-radius:8px;
                          text-decoration:none;font-weight:bold;">
                  Join Group
                </a>
                <p style="margin-top:24px;font-size:12px;color:#999;">
                  If the button doesn't work, copy this link into your browser:<br>
                  <a href="%s" style="color:#1976D2;word-break:break-all;">%s</a>
                </p>
                <p style="margin-top:16px;font-size:12px;color:#bbb;">
                  This invitation expires in 7 days.
                </p>
              </div>
            </body>
            </html>
            """.formatted(safeInviter, safeGroup, safeLink, safeLink, safeLink);
    }

    public static String inviteText(String inviterName, String groupName, String joinLink) {
        return """
            %s has invited you to join the group "%s" on StorySizer.

            Click the link below to join:
            %s

            This invitation expires in 7 days.
            """.formatted(inviterName, groupName, joinLink);
    }

    private static String escapeHtml(String input) {
        if (input == null) return "";
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;");
    }
}
