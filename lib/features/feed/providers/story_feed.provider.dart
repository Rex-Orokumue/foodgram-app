import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/story.model.dart';

class StoryFeedState {
  final List<StoryGroupModel> groups;
  final bool isLoading;

  const StoryFeedState({
    this.groups = const [],
    this.isLoading = false,
  });

  StoryFeedState copyWith({
    List<StoryGroupModel>? groups,
    bool? isLoading,
  }) {
    return StoryFeedState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StoryFeedNotifier extends Notifier<StoryFeedState> {
  @override
  StoryFeedState build() {
    loadStories();
    return const StoryFeedState();
  }

  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/stories/feed');
      final groupsJson =
          response.data['data']['stories'] as List<dynamic>;

      final groups = groupsJson
          .map((g) => StoryGroupModel.fromJson(g as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final storyFeedProvider =
    NotifierProvider<StoryFeedNotifier, StoryFeedState>(() {
  return StoryFeedNotifier();
});