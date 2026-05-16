class GroupMemberModel {
  final String userId;
  final String displayName;
  final String email;
  final String role;
  final String? joinedAt;

  const GroupMemberModel({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] as String?,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}

class GroupInvitationModel {
  final String id;
  final String invitedEmail;
  final String status;
  final String? createdAt;

  const GroupInvitationModel({
    required this.id,
    required this.invitedEmail,
    required this.status,
    this.createdAt,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: json['id'] as String,
      invitedEmail: json['invitedEmail'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class GroupDetailModel {
  final String id;
  final String name;
  final String createdByUserId;
  final String? myRole;
  final List<GroupMemberModel> members;
  final List<GroupInvitationModel> pendingInvitations;

  const GroupDetailModel({
    required this.id,
    required this.name,
    required this.createdByUserId,
    this.myRole,
    required this.members,
    required this.pendingInvitations,
  });

  bool get iAmAdmin => myRole == 'ADMIN';

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdByUserId: json['createdByUserId'] as String,
      myRole: json['myRole'] as String?,
      members: (json['members'] as List? ?? [])
          .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      pendingInvitations: (json['pendingInvitations'] as List? ?? [])
          .map((i) => GroupInvitationModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
