package com.fileini.storysizer.service.group.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "group_invitations")
public class GroupInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long groupId;
    private String invitedEmail;      // lowercase
    private String invitedByUserId;   // JWT sub
    private String tokenHash;         // SHA-256 hex of the raw token (never store raw)
    private String status;            // PENDING | ACCEPTED | CANCELED | EXPIRED
    private Instant expiresAt;
    private Instant createdAt;

    public GroupInvitation() {}

    public GroupInvitation(Long groupId, String invitedEmail, String invitedByUserId,
                           String tokenHash, Instant expiresAt) {
        this.groupId = groupId;
        this.invitedEmail = invitedEmail.toLowerCase();
        this.invitedByUserId = invitedByUserId;
        this.tokenHash = tokenHash;
        this.status = "PENDING";
        this.expiresAt = expiresAt;
        this.createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getGroupId() { return groupId; }
    public String getInvitedEmail() { return invitedEmail; }
    public String getInvitedByUserId() { return invitedByUserId; }
    public String getTokenHash() { return tokenHash; }
    public String getStatus() { return status; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getCreatedAt() { return createdAt; }

    public void setId(Long id) { this.id = id; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }
    public void setInvitedEmail(String invitedEmail) { this.invitedEmail = invitedEmail; }
    public void setInvitedByUserId(String invitedByUserId) { this.invitedByUserId = invitedByUserId; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public void setStatus(String status) { this.status = status; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
