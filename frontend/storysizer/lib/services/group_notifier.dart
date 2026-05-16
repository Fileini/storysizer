import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storysizer/models/group.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/services/data_repository.dart';

// ─── Groups list ─────────────────────────────────────────────────────────────

class GroupsState {
  final List<GroupDetailModel>? groups;
  final bool isLoading;
  final String? error;

  const GroupsState({this.groups, this.isLoading = false, this.error});
}

class GroupsNotifier extends StateNotifier<GroupsState> {
  final DataRepository repository;

  GroupsNotifier({required this.repository}) : super(const GroupsState());

  Future<void> loadGroups() async {
    state = const GroupsState(isLoading: true);
    try {
      final groups = await repository.fetchMyGroups();
      state = GroupsState(groups: groups);
    } catch (e) {
      state = GroupsState(error: e.toString());
    }
  }
}

// ─── Group estimation feed ───────────────────────────────────────────────────

class GroupEstimationFeedState {
  final List<GroupEstimationItemModel>? items;
  final bool isLoading;
  final String? error;

  const GroupEstimationFeedState({this.items, this.isLoading = false, this.error});
}

class GroupEstimationFeedNotifier extends StateNotifier<GroupEstimationFeedState> {
  final DataRepository repository;

  GroupEstimationFeedNotifier({required this.repository})
      : super(const GroupEstimationFeedState());

  Future<void> loadFeed() async {
    state = const GroupEstimationFeedState(isLoading: true);
    try {
      final items = await repository.fetchGroupEstimationFeed();
      state = GroupEstimationFeedState(items: items);
    } catch (e) {
      state = GroupEstimationFeedState(error: e.toString());
    }
  }
}

// ─── Group estimations (per group) ──────────────────────────────────────────

class GroupEstimationsState {
  final List<GroupEstimationItemModel>? items;
  final bool isLoading;
  final String? error;

  const GroupEstimationsState({this.items, this.isLoading = false, this.error});
}

class GroupEstimationsNotifier extends StateNotifier<GroupEstimationsState> {
  final DataRepository repository;
  final String groupId;

  GroupEstimationsNotifier({required this.repository, required this.groupId})
      : super(const GroupEstimationsState());

  Future<void> load() async {
    state = const GroupEstimationsState(isLoading: true);
    try {
      final items = await repository.fetchGroupEstimations(groupId);
      state = GroupEstimationsState(items: items);
    } catch (e) {
      state = GroupEstimationsState(error: e.toString());
    }
  }
}

// ─── Pending count (for badge) ───────────────────────────────────────────────

class PendingCountNotifier extends StateNotifier<int> {
  final DataRepository repository;

  PendingCountNotifier({required this.repository}) : super(0);

  Future<void> refresh() async {
    try {
      final count = await repository.fetchPendingGroupEstimationsCount();
      state = count;
    } catch (_) {
      state = 0;
    }
  }
}
