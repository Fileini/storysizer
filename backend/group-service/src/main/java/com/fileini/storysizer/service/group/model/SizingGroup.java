package com.fileini.storysizer.service.group.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "sizing_group")
public class SizingGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String createdByUserId;   // JWT sub
    private Instant createdAt;
    private Instant deletedAt;        // soft delete

    public SizingGroup() {}

    public SizingGroup(String name, String createdByUserId) {
        this.name = name;
        this.createdByUserId = createdByUserId;
        this.createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getCreatedByUserId() { return createdByUserId; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getDeletedAt() { return deletedAt; }

    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setCreatedByUserId(String createdByUserId) { this.createdByUserId = createdByUserId; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }
}
