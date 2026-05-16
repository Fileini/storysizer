package com.fileini.storysizer.service.group.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(
    name = "group_estimation_votes",
    uniqueConstraints = @UniqueConstraint(columnNames = {"group_estimation_id", "user_id"})
)
public class GroupEstimationVote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "group_estimation_id")
    private Long groupEstimationId;

    @Column(name = "user_id")
    private String userId;          // JWT sub

    private String displayName;     // preferred_username (display only)
    private String status;          // TO_SIZE | SUBMITTED

    private Integer complexity;
    private Integer reach;
    private Integer dimensions;
    private Integer risk;
    private Integer interaction;
    private Integer sizer;

    private Instant submittedAt;

    public GroupEstimationVote() {}

    public GroupEstimationVote(Long groupEstimationId, String userId, String displayName) {
        this.groupEstimationId = groupEstimationId;
        this.userId = userId;
        this.displayName = displayName;
        this.status = "TO_SIZE";
    }

    public Long getId() { return id; }
    public Long getGroupEstimationId() { return groupEstimationId; }
    public String getUserId() { return userId; }
    public String getDisplayName() { return displayName; }
    public String getStatus() { return status; }
    public Integer getComplexity() { return complexity; }
    public Integer getReach() { return reach; }
    public Integer getDimensions() { return dimensions; }
    public Integer getRisk() { return risk; }
    public Integer getInteraction() { return interaction; }
    public Integer getSizer() { return sizer; }
    public Instant getSubmittedAt() { return submittedAt; }

    public void setId(Long id) { this.id = id; }
    public void setGroupEstimationId(Long groupEstimationId) { this.groupEstimationId = groupEstimationId; }
    public void setUserId(String userId) { this.userId = userId; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }
    public void setStatus(String status) { this.status = status; }
    public void setComplexity(Integer complexity) { this.complexity = complexity; }
    public void setReach(Integer reach) { this.reach = reach; }
    public void setDimensions(Integer dimensions) { this.dimensions = dimensions; }
    public void setRisk(Integer risk) { this.risk = risk; }
    public void setInteraction(Integer interaction) { this.interaction = interaction; }
    public void setSizer(Integer sizer) { this.sizer = sizer; }
    public void setSubmittedAt(Instant submittedAt) { this.submittedAt = submittedAt; }
}
