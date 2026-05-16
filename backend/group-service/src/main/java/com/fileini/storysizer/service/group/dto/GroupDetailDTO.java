package com.fileini.storysizer.service.group.dto;

import com.fileini.storysizer.service.group.model.GroupEstimationVote;
import com.fileini.storysizer.service.group.model.GroupInvitation;
import com.fileini.storysizer.service.group.model.GroupMember;
import com.fileini.storysizer.service.group.model.SizingGroup;
import java.util.List;

/** Full group detail returned by GET /groups/{id} */
public class GroupDetailDTO {

    private Long id;
    private String name;
    private String createdByUserId;
    private String myRole;            // ADMIN | MEMBER | null if not member
    private List<GroupMember> members;
    private List<GroupInvitation> pendingInvitations;

    public GroupDetailDTO() {}

    public GroupDetailDTO(SizingGroup group, String myRole,
                          List<GroupMember> members, List<GroupInvitation> pendingInvitations) {
        this.id = group.getId();
        this.name = group.getName();
        this.createdByUserId = group.getCreatedByUserId();
        this.myRole = myRole;
        this.members = members;
        this.pendingInvitations = pendingInvitations;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getCreatedByUserId() { return createdByUserId; }
    public String getMyRole() { return myRole; }
    public List<GroupMember> getMembers() { return members; }
    public List<GroupInvitation> getPendingInvitations() { return pendingInvitations; }

    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setCreatedByUserId(String createdByUserId) { this.createdByUserId = createdByUserId; }
    public void setMyRole(String myRole) { this.myRole = myRole; }
    public void setMembers(List<GroupMember> members) { this.members = members; }
    public void setPendingInvitations(List<GroupInvitation> pendingInvitations) { this.pendingInvitations = pendingInvitations; }
}
