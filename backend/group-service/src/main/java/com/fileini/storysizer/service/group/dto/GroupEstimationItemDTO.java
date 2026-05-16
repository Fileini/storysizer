package com.fileini.storysizer.service.group.dto;

import com.fileini.storysizer.service.group.model.GroupEstimation;

import java.time.Instant;

/**
 * View della GroupEstimation arricchita con campi calcolati per il chiamante:
 * - groupName: nome del gruppo (lookup)
 * - myVoteStatus: stato del voto dell'utente richiedente (TO_SIZE | SUBMITTED | null)
 */
public class GroupEstimationItemDTO {

    private Long id;
    private Long groupId;
    private String groupName;
    private String title;
    private String createdByUserId;
    private Instant createdAt;
    private String myVoteStatus;
    private boolean amIAdmin;

    public GroupEstimationItemDTO() {}

    public static GroupEstimationItemDTO from(GroupEstimation e, String groupName, String myVoteStatus, boolean amIAdmin) {
        GroupEstimationItemDTO dto = new GroupEstimationItemDTO();
        dto.id = e.getId();
        dto.groupId = e.getGroupId();
        dto.groupName = groupName;
        dto.title = e.getTitle();
        dto.createdByUserId = e.getCreatedByUserId();
        dto.createdAt = e.getCreatedAt();
        dto.myVoteStatus = myVoteStatus;
        dto.amIAdmin = amIAdmin;
        return dto;
    }

    public Long getId() { return id; }
    public Long getGroupId() { return groupId; }
    public String getGroupName() { return groupName; }
    public String getTitle() { return title; }
    public String getCreatedByUserId() { return createdByUserId; }
    public Instant getCreatedAt() { return createdAt; }
    public String getMyVoteStatus() { return myVoteStatus; }
    public boolean isAmIAdmin() { return amIAdmin; }

    public void setId(Long id) { this.id = id; }
    public void setGroupId(Long groupId) { this.groupId = groupId; }
    public void setGroupName(String groupName) { this.groupName = groupName; }
    public void setTitle(String title) { this.title = title; }
    public void setCreatedByUserId(String createdByUserId) { this.createdByUserId = createdByUserId; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public void setMyVoteStatus(String myVoteStatus) { this.myVoteStatus = myVoteStatus; }
    public void setAmIAdmin(boolean amIAdmin) { this.amIAdmin = amIAdmin; }
}
