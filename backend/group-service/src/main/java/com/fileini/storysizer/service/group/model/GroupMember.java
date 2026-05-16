package com.fileini.storysizer.service.group.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(
    name = "group_members",
    uniqueConstraints = @UniqueConstraint(columnNames = {"group_id", "user_id"})
)
public class GroupMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_id")
    private Long groupId;

    @Column(name = "user_id")
    private String userId;        // JWT sub (stable)

    private String displayName;   // preferred_username (display only)
    private String email;
    private String role;          // ADMIN | MEMBER
    private Instant joinedAt;

    public GroupMember() {}

    public GroupMember(Long groupId, String userId, String displayName, String email, String role) {
        this.groupId = groupId;
        this.userId = userId;
        this.displayName = displayName;
        this.email = email;
        this.role = role;
        this.joinedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getGroupId() { return groupId; }
    public String getUserId() { return userId; }
    public String getDisplayName() { return displayName; }
    public String getEmail() { return email; }
    public String getRole() { return role; }
    public Instant getJoinedAt() { return joinedAt; }

    public void setId(Long id) { this.id = id; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }
    public void setUserId(String userId) { this.userId = userId; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }
    public void setEmail(String email) { this.email = email; }
    public void setRole(String role) { this.role = role; }
    public void setJoinedAt(Instant joinedAt) { this.joinedAt = joinedAt; }
}
