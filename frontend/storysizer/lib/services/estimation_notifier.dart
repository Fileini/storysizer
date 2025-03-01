import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storysizer/models/estimation.dart';
import 'package:storysizer/services/data_repository.dart';

class EstimationsState {
  final bool isLoading;
  final List<Estimation>? estimations;
  final String? error;

  EstimationsState({this.isLoading = false, this.estimations, this.error});

  EstimationsState copyWith({bool? isLoading, List<Estimation>? estimations, String? error}) {
    return EstimationsState(
      isLoading: isLoading ?? this.isLoading,
      estimations: estimations ?? this.estimations,
      error: error ?? this.error,
    );
  }
}

class EstimationsNotifier extends StateNotifier<EstimationsState> {
  final DataRepository repository;

  EstimationsNotifier({required this.repository}) : super(EstimationsState());

  // Carica le estimations dalla API GraphQL
  Future<void> loadEstimations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final estimations = await repository.fetchEstimations();
      state = state.copyWith(isLoading: false, estimations: estimations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  
}

class EstimationCreationState {
  final bool isLoading;
  final Estimation? estimation;
  final String? error;
  
  EstimationCreationState({this.isLoading = false, this.estimation, this.error});
  
  EstimationCreationState copyWith({bool? isLoading, Estimation? estimation, String? error}) {
    return EstimationCreationState(
      isLoading: isLoading ?? this.isLoading,
      estimation: estimation ?? this.estimation,
      error: error ?? this.error,
    );
  }
}

class EstimationCreationNotifier extends StateNotifier<EstimationCreationState> {
  final DataRepository repository;
  
  EstimationCreationNotifier({required this.repository})
      : super(EstimationCreationState());
  
  Future<void> createEstimation({
    required String name,
    required int complexity,
    required int reach,
    required int dimension,
    required int risk,
    required int interaction,
    required String storyId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final estimation = await repository.createEstimation(
        name: name,
        complexity: complexity,
        reach: reach,
        dimension: dimension,
        risk: risk,
        interaction: interaction,
        storyId: storyId,
      );
      state = state.copyWith(isLoading: false, estimation: estimation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

}
