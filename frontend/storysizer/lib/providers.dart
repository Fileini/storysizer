import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:storysizer/services/auth_service.dart';
import 'package:storysizer/services/data_repository.dart';
import 'package:storysizer/services/story_notifier.dart';
import 'services/themeprovider.dart';
import 'routes.dart';

final themeModeProvider = ChangeNotifierProvider<ThemeModeProvider>(
  (ref) => ThemeModeProvider(),
);

final routesProvider = Provider<StszRoutes>(
  (ref) => StszRoutes(),
);

final storyCreationNotifierProvider = StateNotifierProvider<StoryCreationNotifier, StoryCreationState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return StoryCreationNotifier(repository: repository);
});

// Provider che espone lo StoriesNotifier, utilizzando il DataRepository.
final storiesNotifierProvider = StateNotifierProvider<StoriesNotifier, StoriesState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return StoriesNotifier(repository: repository);
});

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return DataRepository(client: client);
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final authService = ref.watch(authServiceProvider);

  final authLink = AuthLink(
    getToken: () async {
      final token = await authService.getAccessToken();
          print('Token usato per la richiesta: $token'); // Debug

      return 'Bearer $token';
    },
  );

  final httpLink = HttpLink('https://api.storysizer.public.cluster.local.com/graphql');
  final link = authLink.concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: link,
  );
});