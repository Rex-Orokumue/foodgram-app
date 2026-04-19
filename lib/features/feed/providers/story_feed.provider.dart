import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/story.model.dart';

class StoryFeedState {
  final List<StoryGroupModel> groups;
  final StoryGroupModel? ownStories;
  final bool isLoading;

  const StoryFeedState({
    this.groups = const [],
    this.ownStories,
    this.isLoading = false,
  });

  StoryFeedState copyWith({
    List<StoryGroupModel>? groups,
    StoryGroupModel? ownStories,
    bool? isLoading,
    bool clearOwnStories = false,
  }) {
    return StoryFeedState(
      groups: groups ?? this.groups,
      ownStories: clearOwnStories ? null : ownStories ?? this.ownStories,
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

      // Load feed stories and own stories simultaneously
      final results = await Future.wait([
        dio.get('/stories/feed'),
        dio.get('/stories/me'),
      ]);

      // Parse feed stories
      final groupsJson =
          results[0].data['data']['stories'] as List<dynamic>;
      final groups = groupsJson
          .map((g) => StoryGroupModel.fromJson(g as Map<String, dynamic>))
          .toList();

      // Parse own stories
      final ownStoriesJson =
          results[1].data['data']['stories'] as List<dynamic>;

      StoryGroupModel? ownStories;
      if (ownStoriesJson.isNotEmpty) {
        final userId = await SecureStorage.getUserId() ?? '';
        final username = await SecureStorage.getUsername() ?? '';


        ownStories = StoryGroupModel.fromJson({
          'user_id': userId,
          'username': username,
          'display_name': username,
          'avatar_url': null,
          'is_verified': false,
          'has_unviewed': true,
          'stories': ownStoriesJson,
        });
      }

      state = state.copyWith(
        groups: groups,
        ownStories: ownStories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void markGroupAsViewed(String userId) {
    final updatedGroups = state.groups.map((g) {
      if (g.userId == userId) return _copyGroupAsViewed(g);
      return g;
    }).toList();

    // Keep own stories visible but grey (not removed)
    final updatedOwn = state.ownStories?.userId == userId
        ? _copyGroupAsViewed(state.ownStories!)
        : state.ownStories;

    state = StoryFeedState(
      groups: updatedGroups,
      ownStories: updatedOwn,
      isLoading: state.isLoading,
    );
  }

  StoryGroupModel _copyGroupAsViewed(StoryGroupModel g) {
    return StoryGroupModel.fromJson({
      'user_id': g.userId,
      'username': g.username,
      'display_name': g.displayName,
      'avatar_url': g.avatarUrl,
      'is_verified': g.isVerified,
      'has_unviewed': false,
      'stories': g.stories
          .map((s) => {
                'id': s.id,
                'user_id': s.userId,
                'media_url': s.mediaUrl,
                'media_type': s.mediaType,
                'caption': s.caption,
                'expires_at': s.expiresAt.toIso8601String(),
                'created_at': s.createdAt.toIso8601String(),
                'username': s.username,
                'display_name': s.displayName,
                'avatar_url': s.avatarUrl,
                'is_verified': s.isVerified,
                'viewed_by_me': true,
              })
          .toList(),
    });
  }
}

final storyFeedProvider =
    NotifierProvider<StoryFeedNotifier, StoryFeedState>(() {
  return StoryFeedNotifier();
});