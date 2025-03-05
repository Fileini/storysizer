
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storysizer/models/story.dart';
import 'package:storysizer/services/data_repository.dart';


class StoriesState {
  final bool isLoading;
  final List<Story>? stories;
  final String? error;

  StoriesState({this.isLoading = false, this.stories, this.error});

  StoriesState copyWith({bool? isLoading, List<Story>? stories, String? error}) {
    return StoriesState(
      isLoading: isLoading ?? this.isLoading,
      stories: stories ?? this.stories,
      error: error ?? this.error,
    );
  }
}
class StoriesNotifier extends StateNotifier<StoriesState> {
  final DataRepository repository;

  StoriesNotifier({required this.repository}) : super(StoriesState());

  // Metodo per caricare le stories dalla API GraphQL.
  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stories = await repository.fetchStories();
      state = state.copyWith(isLoading: false, stories: stories);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
Future<void> deleteStory(String id) async {
  try {
    final success = await repository.deleteStory(id);
    if (success) {
      // Crea una nuova lista per forzare la ricostruzione
      final updatedStories = List<Story>.from(state.stories ?? []);
      updatedStories.removeWhere((story) => story.id == id);
      state = state.copyWith(stories: updatedStories);
    }
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
}


class StoryCreationState {
  final bool isLoading;
  final Story? story;
  final String? error;
  
  StoryCreationState({this.isLoading = false, this.story, this.error});
  
  StoryCreationState copyWith({bool? isLoading, Story? story, String? error}) {
    return StoryCreationState(
      isLoading: isLoading ?? this.isLoading,
      story: story ?? this.story,
      error: error ?? this.error,
    );
  }
}

class StoryCreationNotifier extends StateNotifier<StoryCreationState> {
  final DataRepository repository;
  StoryCreationNotifier({required this.repository}) : super(StoryCreationState());
  
  Future<void> createStory(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final story = await repository.createStory(name);
      state = state.copyWith(isLoading: false, story: story);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

