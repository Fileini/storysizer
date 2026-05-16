import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:storysizer/models/estimation.dart';
import 'package:storysizer/models/group.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/services/auth_service.dart';
import 'package:storysizer/services/data_repository.dart';
import 'package:storysizer/services/estimation_notifier.dart';
import 'package:storysizer/services/group_notifier.dart';
import 'package:storysizer/services/story_notifier.dart';
import 'services/themeprovider.dart';
import 'routes.dart';
import 'package:flutter/material.dart';


  final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();


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

final storiesNotifierProvider = StateNotifierProvider<StoriesNotifier, StoriesState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return StoriesNotifier(repository: repository);
});

final estimationsNotifierProvider = StateNotifierProvider<EstimationsNotifier, EstimationsState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return EstimationsNotifier(repository: repository);
});

final estimationProvider = FutureProvider.family<Estimation, String>((ref, id) async {
  final repository = ref.watch(dataRepositoryProvider);
  // Se esiste un metodo dedicato, usalo, altrimenti filtra la lista
  final estimations = await repository.fetchEstimations();
  return estimations.firstWhere(
    (estimation) => estimation.id == id,
    orElse: () => throw Exception('Estimation not found'),
  );
});

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return DataRepository(client: client);
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);

// ─── Group providers ──────────────────────────────────────────────────────────

final groupsNotifierProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return GroupsNotifier(repository: repository);
});

final groupEstimationFeedNotifierProvider =
    StateNotifierProvider<GroupEstimationFeedNotifier, GroupEstimationFeedState>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return GroupEstimationFeedNotifier(repository: repository);
});

final groupEstimationsNotifierProvider =
    StateNotifierProvider.family<GroupEstimationsNotifier, GroupEstimationsState, String>(
        (ref, groupId) {
  final repository = ref.watch(dataRepositoryProvider);
  return GroupEstimationsNotifier(repository: repository, groupId: groupId);
});

final pendingCountNotifierProvider =
    StateNotifierProvider<PendingCountNotifier, int>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return PendingCountNotifier(repository: repository);
});

final groupDetailProvider = FutureProvider.family<GroupDetailModel, String>((ref, id) async {
  final repository = ref.watch(dataRepositoryProvider);
  return repository.fetchGroup(id);
});

final groupEstimationDashboardProvider =
    FutureProvider.family<GroupEstimationDashboardModel, String>((ref, estimationId) async {
  final repository = ref.watch(dataRepositoryProvider);
  return repository.fetchGroupEstimationDashboard(estimationId);
});

final myVoteProvider =
    FutureProvider.family<GroupEstimationVoteModel?, String>((ref, estimationId) async {
  final repository = ref.watch(dataRepositoryProvider);
  return repository.fetchMyVote(estimationId);
});

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final authService = ref.watch(authServiceProvider);

  final authLink = AuthLink(
    getToken: () async {
      final token = await authService.getAccessToken();
        //  print('Token usato per la richiesta: $token'); // Debug

      return 'Bearer $token';
    },
  );

  final httpLink = HttpLink('https://api.storysizer.org/graphql');
  final link = authLink.concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: InMemoryStore()),
    link: link,
  );
});