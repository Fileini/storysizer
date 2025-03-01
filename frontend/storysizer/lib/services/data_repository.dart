import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:storysizer/models/estimation.dart';
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
          owner
        }
      }
    ''';
    
    final result = await client.query(QueryOptions(document: gql(query)));
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
          owner
          complexity
          reach
          dimensions
          risk
          interaction
          size
          story {
            id
            name
            owner
          }
        }
      }
    ''';
    
    final result = await client.query(QueryOptions(document: gql(query)));
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
          owner
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
    required int dimension,
    required int risk,
    required int interaction,
    required String storyId,
  }) async {
    const String mutation = r'''
      mutation CreateEstimation(
        $name: String!, 
        $complexity: Int!, 
        $reach: Int!, 
        $dimension: Int!, 
        $risk: Int!, 
        $interaction: Int!, 
        $storyId: String!
      ) {
        createEstimation(
          name: $name, 
          complexity: $complexity, 
          reach: $reach, 
          dimension: $dimension, 
          risk: $risk, 
          interaction: $interaction, 
          storyId: $storyId
        ) {
          id
          owner
          complexity
          reach
          dimensions
          risk
          interaction
          size
          story {
            id
            name
            owner
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
          'dimension': dimension,
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
  

}
