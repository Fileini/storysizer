package com.fileini.storysizer.service.graphqlgateway.model;

import java.util.List;

public class GroupDetail {

    private String id;
    private String name;
    private String createdByUserId;
    private String myRole;
    private List<GroupMember> members;
    private List<GroupInvitation> pendingInvitations;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(String createdByUserId) { this.createdByUserId = createdByUserId; }

    public String getMyRole() { return myRole; }
    public void setMyRole(String myRole) { this.myRole = myRole; }

    public List<GroupMember> getMembers() { return members; }
    public void setMembers(List<GroupMember> members) { this.members = members; }

    public List<GroupInvitation> getPendingInvitations() { return pendingInvitations; }
    public void setPendingInvitations(List<GroupInvitation> pendingInvitations) {
        this.pendingInvitations = pendingInvitations;
    }
}
