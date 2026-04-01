import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/story.model.dart';

class StoryViewerState {
  final List<StoryModel> stories;
  final bool isLoading;
  final String? error;

  const StoryViewerState({
    this.stories = const [],
    this.isLoading = false,
    this.error,
  });

  StoryViewerState copyWith({
    List<StoryModel>? stories,
    bool? isLoading,
    String? error,
  }) {
    return StoryViewerState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StoryViewerNotifier extends Notifier<StoryViewerState> {
  @override
  StoryViewerState build() {
    return const StoryViewerState();
  }

  Future<void> loadStories(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/stories/feed');
      final groupsJson =
          response.data['data']['stories'] as List<dynamic>;

      // Find the group for this specific user
      List<StoryModel> userStories = [];

      for (final group in groupsJson) {
        final groupData = group as Map<String, dynamic>;
        if (groupData['user_id'] == userId) {
          final storiesJson = groupData['stories'] as List<dynamic>;
          userStories = storiesJson
              .map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
              .toList();
          break;
        }
      }

      state = state.copyWith(
        stories: userStories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stories',
      );
    }
  }

  Future<void> viewStory(String storyId) async {
    try {
      final dio = ApiClient.instance;
      await dio.post('/stories/$storyId/view');
    } catch (e) {
      // View recording failed silently
    }
  }
}

final storyViewerProvider =
    NotifierProvider<StoryViewerNotifier, StoryViewerState>(() {
  return StoryViewerNotifier();
});