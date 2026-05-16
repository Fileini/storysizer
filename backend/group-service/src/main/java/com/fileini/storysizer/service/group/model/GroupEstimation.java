package com.fileini.storysizer.service.group.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "group_estimations")
public class GroupEstimation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long groupId;
    private String title;
    private String createdByUserId;
    private Instant createdAt;
    private Instant updatedAt;

    public GroupEstimation() {}

    public GroupEstimation(Long groupId, String title, String createdByUserId) {
        this.groupId = groupId;
        this.title = title;
        this.createdByUserId = createdByUserId;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getGroupId() { return groupId; }
    public String getTitle() { return title; }
    public String getCreatedByUserId() { return createdByUserId; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setId(Long id) { this.id = id; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }
    public void setTitle(String title) { this.title = title; }
    public void setCreatedByUserId(String createdByUserId) { this.createdByUserId = createdByUserId; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
