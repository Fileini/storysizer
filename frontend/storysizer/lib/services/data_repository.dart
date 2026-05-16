import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:storysizer/models/estimation.dart';
import 'package:storysizer/models/group.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/models/story.dart';

class DataRepository {
  final GraphQLClient client;
  DataRepository({required this.client});
  
  // Recupera la lista delle stories
  Future<List<Story>> fetchStories() async {
    const String query = r'''
      query GetStories {
        stories {
          id
          name
        }
      }
    ''';
    
    final result = await client.query(QueryOptions(document: gql(query),
    fetchPolicy: FetchPolicy.networkOnly,));
    if(result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List storiesData = result.data?['stories'] ?? [];
    return storiesData.map((story) => Story.fromJson(story)).toList();
  }
  
  // Recupera la lista delle estimations
  Future<List<Estimation>> fetchEstimations() async {
    const String query = r'''
      query GetEstimations {
        estimations {
          id
          complexity
          reach
          dimensions
          risk
          interaction
          sizer
          story {
            id
            name
          }
        }
      }
    ''';
    
    final result = await client.query(QueryOptions(document: gql(query),
    fetchPolicy: FetchPolicy.networkOnly,));
    if(result.hasException) {
      throw Exception(result.exception.toString());
    }
    
    final List estimationsData = result.data?['estimations'] ?? [];
    return estimationsData.map((e) => Estimation.fromJson(e)).toList();

  }
  
  // Crea una nuova Story
  Future<Story> createStory(String name) async {
    const String mutation = r'''
      mutation CreateStory($name: String!) {
        createStory(name: $name) {
          id
          name
        }
      }
    ''';
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'name': name},
      ),
    );
    
    if(result.hasException) {
      throw Exception(result.exception.toString());
    }
    
    return Story.fromJson(result.data!['createStory']);
  }
  
  // Crea una nuova Estimation
  Future<Estimation> createEstimation({
    required String name,
    required int complexity,
    required int reach,
    required int dimensions,
    required int risk,
    required int interaction,
    required String storyId,
  }) async {
    const String mutation = r'''
      mutation CreateEstimation(
        $name: String!, 
        $complexity: Int!, 
        $reach: Int!, 
        $dimensions: Int!, 
        $risk: Int!, 
        $interaction: Int!, 
        $storyId: String!
      ) {
        createEstimation(
          name: $name, 
          complexity: $complexity, 
          reach: $reach, 
          dimensions: $dimensions, 
          risk: $risk, 
          interaction: $interaction, 
          storyId: $storyId
        ) {
          id
          complexity
          reach
          dimensions
          risk
          interaction
          sizer
          story {
            id
            name
          }
        }
      }
    ''';
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'name': name,
          'complexity': complexity,
          'reach': reach,
          'dimensions': dimensions,
          'risk': risk,
          'interaction': interaction,
          'storyId': storyId,
        },
      ),
    );
    
    if(result.hasException) {
      throw Exception(result.exception.toString());
    }
    
    return Estimation.fromJson(result.data!['createEstimation']);
  }
  
  // Cancella una Story
  Future<bool> deleteStory(String id) async {
    const String mutation = r'''
      mutation DeleteStory($id: ID!) {
        deleteStory(id: $id)
      }
    ''';
    
    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': id},
      ),
    );
    
    if(result.hasException) {
      throw Exception(result.exception.toString());
    }
    
    return result.data!['deleteStory'] as bool;
  }

  // Cancella l'account e tutti i dati dell'utente (GDPR - diritto alla cancellazione)
  Future<bool> deleteMyAccount() async {
    const String mutation = r'''
      mutation DeleteMyAccount {
        deleteMyAccount
      }
    ''';

    final result = await client.mutate(
      MutationOptions(document: gql(mutation)),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['deleteMyAccount'] as bool;
  }

  // Esporta tutti i dati dell'utente (GDPR - diritto alla portabilità)
  Future<Map<String, dynamic>> exportMyData() async {
    const String query = r'''
      query ExportMyData {
        exportMyData {
          stories {
            id
            name
          }
          estimations {
            id
            complexity
            reach
            dimensions
            risk
            interaction
            sizer
            story {
              id
              name
            }
          }
        }
      }
    ''';

    final result = await client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['exportMyData'] as Map<String, dynamic>;
  }

  // ─── Groups ─────────────────────────────────────────────────────────────────

  Future<List<GroupDetailModel>> fetchMyGroups() async {
    const String query = r'''
      query MyGroups {
        myGroups {
          id name createdByUserId myRole
          members { userId displayName email role joinedAt }
          pendingInvitations { id invitedEmail status createdAt }
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    final data = result.data?['myGroups'] as List? ?? [];
    return data.map((g) => GroupDetailModel.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<GroupDetailModel> fetchGroup(String id) async {
    const String query = r'''
      query Group($id: ID!) {
        group(id: $id) {
          id name createdByUserId myRole
          members { userId displayName email role joinedAt }
          pendingInvitations { id invitedEmail status createdAt }
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupDetailModel.fromJson(result.data!['group'] as Map<String, dynamic>);
  }

  Future<GroupDetailModel> createGroup(String name) async {
    const String mutation = r'''
      mutation CreateGroup($name: String!) {
        createGroup(name: $name) {
          id name createdByUserId myRole
          members { userId displayName email role }
          pendingInvitations { id invitedEmail status }
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'name': name},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupDetailModel.fromJson(result.data!['createGroup'] as Map<String, dynamic>);
  }

  Future<GroupDetailModel> renameGroup(String groupId, String name) async {
    const String mutation = r'''
      mutation RenameGroup($groupId: ID!, $name: String!) {
        renameGroup(groupId: $groupId, name: $name) {
          id name createdByUserId myRole
          members { userId displayName email role }
          pendingInvitations { id invitedEmail status }
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'name': name},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupDetailModel.fromJson(result.data!['renameGroup'] as Map<String, dynamic>);
  }

  Future<bool> deleteGroup(String groupId) async {
    const String mutation = r'''
      mutation DeleteGroup($groupId: ID!) {
        deleteGroup(groupId: $groupId)
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['deleteGroup'] as bool;
  }

  Future<void> inviteToGroup(String groupId, String email) async {
    const String mutation = r'''
      mutation InviteToGroup($groupId: ID!, $email: String!) {
        inviteToGroup(groupId: $groupId, email: $email) {
          id invitedEmail status
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'email': email},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
  }

  Future<bool> cancelGroupInvite(String groupId, String invitationId) async {
    const String mutation = r'''
      mutation CancelGroupInvite($groupId: ID!, $invitationId: ID!) {
        cancelGroupInvite(groupId: $groupId, invitationId: $invitationId)
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'invitationId': invitationId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['cancelGroupInvite'] as bool;
  }

  Future<bool> promoteGroupMember(String groupId, String targetUserId) async {
    const String mutation = r'''
      mutation PromoteGroupMember($groupId: ID!, $targetUserId: String!) {
        promoteGroupMember(groupId: $groupId, targetUserId: $targetUserId) {
          userId role
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'targetUserId': targetUserId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return true;
  }

  Future<bool> removeGroupMember(String groupId, String targetUserId) async {
    const String mutation = r'''
      mutation RemoveGroupMember($groupId: ID!, $targetUserId: String!) {
        removeGroupMember(groupId: $groupId, targetUserId: $targetUserId)
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'targetUserId': targetUserId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['removeGroupMember'] as bool;
  }

  Future<GroupDetailModel> acceptGroupInvite(String token) async {
    const String mutation = r'''
      mutation AcceptGroupInvite($token: String!) {
        acceptGroupInvite(token: $token) {
          id name createdByUserId myRole
          members { userId displayName email role }
          pendingInvitations { id invitedEmail status }
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'token': token},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupDetailModel.fromJson(result.data!['acceptGroupInvite'] as Map<String, dynamic>);
  }

  // ─── Group Estimations ───────────────────────────────────────────────────────

  Future<List<GroupEstimationItemModel>> fetchGroupEstimations(String groupId) async {
    const String query = r'''
      query GroupEstimations($groupId: ID!) {
        groupEstimations(groupId: $groupId) {
          id groupId title myVoteStatus createdAt
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      variables: {'groupId': groupId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    final data = result.data?['groupEstimations'] as List? ?? [];
    return data.map((e) => GroupEstimationItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GroupEstimationItemModel>> fetchGroupEstimationFeed() async {
    const String query = r'''
      query GroupEstimationFeed {
        groupEstimationFeed {
          id groupId groupName title myVoteStatus createdAt
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    final data = result.data?['groupEstimationFeed'] as List? ?? [];
    return data.map((e) => GroupEstimationItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> fetchPendingGroupEstimationsCount() async {
    const String query = r'''
      query PendingCount {
        myPendingGroupEstimationsCount
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data?['myPendingGroupEstimationsCount'] as int? ?? 0;
  }

  Future<GroupEstimationVoteModel?> fetchMyVote(String groupEstimationId) async {
    const String query = r'''
      query MyVote($groupEstimationId: ID!) {
        myVote(groupEstimationId: $groupEstimationId) {
          id groupEstimationId userId displayName status
          complexity reach dimensions risk interaction sizer submittedAt
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      variables: {'groupEstimationId': groupEstimationId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    final data = result.data?['myVote'];
    return data == null ? null : GroupEstimationVoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<GroupEstimationDashboardModel> fetchGroupEstimationDashboard(String groupEstimationId) async {
    const String query = r'''
      query Dashboard($groupEstimationId: ID!) {
        groupEstimationDashboard(groupEstimationId: $groupEstimationId) {
          groupEstimationId title groupName totalVoters submittedVoters
          complexityAvg reachAvg dimensionsAvg riskAvg interactionAvg
          complexityAgreement reachAgreement dimensionsAgreement riskAgreement interactionAgreement
        }
      }
    ''';
    final result = await client.query(QueryOptions(
      document: gql(query),
      variables: {'groupEstimationId': groupEstimationId},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupEstimationDashboardModel.fromJson(
        result.data!['groupEstimationDashboard'] as Map<String, dynamic>);
  }

  Future<GroupEstimationItemModel> createGroupEstimation(String groupId, String title) async {
    const String mutation = r'''
      mutation CreateGroupEstimation($groupId: ID!, $title: String!) {
        createGroupEstimation(groupId: $groupId, title: $title) {
          id groupId title myVoteStatus createdAt
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupId': groupId, 'title': title},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupEstimationItemModel.fromJson(
        result.data!['createGroupEstimation'] as Map<String, dynamic>);
  }

  Future<GroupEstimationVoteModel> submitGroupEstimationVote({
    required String groupEstimationId,
    required int complexity,
    required int reach,
    required int dimensions,
    required int risk,
    required int interaction,
  }) async {
    const String mutation = r'''
      mutation SubmitVote(
        $groupEstimationId: ID!,
        $complexity: Int!, $reach: Int!, $dimensions: Int!, $risk: Int!, $interaction: Int!
      ) {
        submitGroupEstimationVote(
          groupEstimationId: $groupEstimationId,
          complexity: $complexity, reach: $reach, dimensions: $dimensions,
          risk: $risk, interaction: $interaction
        ) {
          id groupEstimationId userId status sizer submittedAt
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {
        'groupEstimationId': groupEstimationId,
        'complexity': complexity,
        'reach': reach,
        'dimensions': dimensions,
        'risk': risk,
        'interaction': interaction,
      },
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupEstimationVoteModel.fromJson(
        result.data!['submitGroupEstimationVote'] as Map<String, dynamic>);
  }

  Future<bool> restartGroupEstimation(String groupEstimationId) async {
    const String mutation = r'''
      mutation RestartGroupEstimation($groupEstimationId: ID!) {
        restartGroupEstimation(groupEstimationId: $groupEstimationId)
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupEstimationId': groupEstimationId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['restartGroupEstimation'] as bool;
  }

  Future<GroupEstimationItemModel> renameGroupEstimation(
      String groupEstimationId, String title) async {
    const String mutation = r'''
      mutation RenameGroupEstimation($groupEstimationId: ID!, $title: String!) {
        renameGroupEstimation(groupEstimationId: $groupEstimationId, title: $title) {
          id groupId title myVoteStatus createdAt
        }
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupEstimationId': groupEstimationId, 'title': title},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return GroupEstimationItemModel.fromJson(
        result.data!['renameGroupEstimation'] as Map<String, dynamic>);
  }

  Future<bool> deleteGroupEstimation(String groupEstimationId) async {
    const String mutation = r'''
      mutation DeleteGroupEstimation($groupEstimationId: ID!) {
        deleteGroupEstimation(groupEstimationId: $groupEstimationId)
      }
    ''';
    final result = await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'groupEstimationId': groupEstimationId},
    ));
    if (result.hasException) throw Exception(result.exception.toString());
    return result.data!['deleteGroupEstimation'] as bool;
  }
}

