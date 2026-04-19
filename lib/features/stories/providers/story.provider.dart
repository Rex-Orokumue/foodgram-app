import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/story.model.dart';
import '../../../core/storage/secure_storage.dart';

class StoryViewerState {
  final List<StoryGroupModel> allGroups;
  final int currentGroupIndex;
  final bool isLoading;
  final String? error;

  const StoryViewerState({
    this.allGroups = const [],
    this.currentGroupIndex = 0,
    this.isLoading = false,
    this.error,
  });

  StoryViewerState copyWith({
    List<StoryGroupModel>? allGroups,
    int? currentGroupIndex,
    bool? isLoading,
    String? error,
  }) {
    return StoryViewerState(
      allGroups: allGroups ?? this.allGroups,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  StoryGroupModel? get currentGroup =>
      allGroups.isEmpty ? null : allGroups[currentGroupIndex];

  List<StoryModel> get currentStories => currentGroup?.stories ?? [];

  bool get hasNextGroup => currentGroupIndex < allGroups.length - 1;
  bool get hasPreviousGroup => currentGroupIndex > 0;
}

class StoryViewerNotifier extends Notifier<StoryViewerState> {
  @override
  StoryViewerState build() => const StoryViewerState();

  Future<void> loadStories(String startUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final currentUserId = await SecureStorage.getUserId() ?? '';

      final List<StoryGroupModel> allGroups = [];

      // Fetch own profile, own stories, and feed stories simultaneously
      final results = await Future.wait([
        dio.get('/auth/me'),
        dio.get('/stories/me'),
        dio.get('/stories/feed'),
      ]);

      final profileData = results[0].data['data']['user'];
      final ownDisplayName = profileData['display_name'] as String? ??
          profileData['username'] as String? ?? '';
      final ownUsername = profileData['username'] as String? ?? '';
      final ownAvatarUrl = profileData['avatar_url'] as String?;
      final ownIsVerified = profileData['is_verified'] as bool? ?? false;

      final ownStoriesJson =
          results[1].data['data']['stories'] as List<dynamic>;

      if (ownStoriesJson.isNotEmpty) {
        final enrichedOwn = ownStoriesJson.map((s) {
          final map = Map<String, dynamic>.from(s as Map<String, dynamic>);
          map['username'] = ownUsername;
          map['display_name'] = ownDisplayName;
          map['avatar_url'] = ownAvatarUrl;
          map['is_verified'] = ownIsVerified;
          map['viewed_by_me'] = map['viewed_by_me'] ?? false;
          return map;
        }).toList();

        allGroups.add(StoryGroupModel.fromJson({
          'user_id': currentUserId,
          'username': ownUsername,
          'display_name': ownDisplayName,
          'avatar_url': ownAvatarUrl,
          'is_verified': ownIsVerified,
          'has_unviewed': enrichedOwn.any(
            (s) => (s['viewed_by_me'] as bool? ?? false) == false,
          ),
          'stories': enrichedOwn,
        }));
      }

      // Feed stories
      final groupsJson =
          results[2].data['data']['stories'] as List<dynamic>;

      for (final g in groupsJson) {
        final groupData = g as Map<String, dynamic>;
        final storiesJson = groupData['stories'] as List<dynamic>;

        final groupUsername = groupData['username'] as String? ?? '';
        final groupDisplayName =
            groupData['display_name'] as String? ?? groupUsername;
        final groupAvatarUrl = groupData['avatar_url'] as String?;
        final groupIsVerified = groupData['is_verified'] as bool? ?? false;

        final enrichedStories = storiesJson.map((s) {
          final map = Map<String, dynamic>.from(s as Map<String, dynamic>);
          if (map['username'] == null || (map['username'] as String).isEmpty) {
            map['username'] = groupUsername;
          }
          if (map['display_name'] == null ||
              (map['display_name'] as String).isEmpty) {
            map['display_name'] = groupDisplayName;
          }
          map['avatar_url'] ??= groupAvatarUrl;
          map['is_verified'] ??= groupIsVerified;
          return map;
        }).toList();

        allGroups.add(StoryGroupModel.fromJson({
          ...groupData,
          'stories': enrichedStories,
        }));
      }

      // Find starting group index
      int startIndex =
          allGroups.indexWhere((g) => g.userId == startUserId);
      if (startIndex < 0) startIndex = 0;

      state = state.copyWith(
        allGroups: allGroups,
        currentGroupIndex: startIndex,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stories',
      );
    }
  }

  void goToNextGroup() {
    if (state.hasNextGroup) {
      state = state.copyWith(
        currentGroupIndex: state.currentGroupIndex + 1,
      );
    }
  }

  void goToPreviousGroup() {
    if (state.hasPreviousGroup) {
      state = state.copyWith(
        currentGroupIndex: state.currentGroupIndex - 1,
      );
    }
  }

  Future<void> viewStory(String storyId) async {
    try {
      final dio = ApiClient.instance;
      await dio.post('/stories/$storyId/view');
    } catch (_) {}
  }
}

final storyViewerProvider =
    NotifierProvider<StoryViewerNotifier, StoryViewerState>(() {
  return StoryViewerNotifier();
});