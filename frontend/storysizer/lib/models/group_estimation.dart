class GroupEstimationItemModel {
  final String id;
  final String groupId;
  final String? groupName;
  final String title;
  final String? myVoteStatus; // TO_SIZE | SUBMITTED
  final bool amIAdmin;
  final String? createdAt;

  const GroupEstimationItemModel({
    required this.id,
    required this.groupId,
    this.groupName,
    required this.title,
    this.myVoteStatus,
    this.amIAdmin = false,
    this.createdAt,
  });

  bool get isPending => myVoteStatus == 'TO_SIZE';

  factory GroupEstimationItemModel.fromJson(Map<String, dynamic> json) {
    return GroupEstimationItemModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String?,
      title: json['title'] as String,
      myVoteStatus: json['myVoteStatus'] as String?,
      amIAdmin: json['amIAdmin'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class GroupEstimationVoteModel {
  final String id;
  final String groupEstimationId;
  final String userId;
  final String? displayName;
  final String status;
  final int? complexity;
  final int? reach;
  final int? dimensions;
  final int? risk;
  final int? interaction;
  final int? sizer;
  final String? submittedAt;

  const GroupEstimationVoteModel({
    required this.id,
    required this.groupEstimationId,
    required this.userId,
    this.displayName,
    required this.status,
    this.complexity,
    this.reach,
    this.dimensions,
    this.risk,
    this.interaction,
    this.sizer,
    this.submittedAt,
  });

  bool get isSubmitted => status == 'SUBMITTED';

  factory GroupEstimationVoteModel.fromJson(Map<String, dynamic> json) {
    return GroupEstimationVoteModel(
      id: json['id'] as String,
      groupEstimationId: json['groupEstimationId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      status: json['status'] as String,
      complexity: json['complexity'] as int?,
      reach: json['reach'] as int?,
      dimensions: json['dimensions'] as int?,
      risk: json['risk'] as int?,
      interaction: json['interaction'] as int?,
      sizer: json['sizer'] as int?,
      submittedAt: json['submittedAt'] as String?,
    );
  }
}

class GroupEstimationDashboardModel {
  final String groupEstimationId;
  final String title;
  final String groupName;
  final int totalVoters;
  final int submittedVoters;
  final double complexityAvg;
  final double reachAvg;
  final double dimensionsAvg;
  final double riskAvg;
  final double interactionAvg;
  final double complexityAgreement;
  final double reachAgreement;
  final double dimensionsAgreement;
  final double riskAgreement;
  final double interactionAgreement;

  const GroupEstimationDashboardModel({
    required this.groupEstimationId,
    required this.title,
    required this.groupName,
    required this.totalVoters,
    required this.submittedVoters,
    required this.complexityAvg,
    required this.reachAvg,
    required this.dimensionsAvg,
    required this.riskAvg,
    required this.interactionAvg,
    required this.complexityAgreement,
    required this.reachAgreement,
    required this.dimensionsAgreement,
    required this.riskAgreement,
    required this.interactionAgreement,
  });

  bool get allVoted => submittedVoters >= totalVoters && totalVoters > 0;

  factory GroupEstimationDashboardModel.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0.0;
    int i(String k) => (json[k] as num?)?.toInt() ?? 0;
    return GroupEstimationDashboardModel(
      groupEstimationId: json['groupEstimationId'] as String,
      title: json['title'] as String,
      groupName: json['groupName'] as String,
      totalVoters: i('totalVoters'),
      submittedVoters: i('submittedVoters'),
      complexityAvg: d('complexityAvg'),
      reachAvg: d('reachAvg'),
      dimensionsAvg: d('dimensionsAvg'),
      riskAvg: d('riskAvg'),
      interactionAvg: d('interactionAvg'),
      complexityAgreement: d('complexityAgreement'),
      reachAgreement: d('reachAgreement'),
      dimensionsAgreement: d('dimensionsAgreement'),
      riskAgreement: d('riskAgreement'),
      interactionAgreement: d('interactionAgreement'),
    );
  }
}
