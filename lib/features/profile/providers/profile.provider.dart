import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.model.dart';
import '../../../shared/models/post.model.dart';

class ProfileState {
  final UserModel? user;
  final List<PostModel> posts;
  final bool isLoading;
  final bool isLoadingPosts;
  final bool isPrivate;
  final String? error;

  const ProfileState({
    this.user,
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingPosts = false,
    this.isPrivate = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    List<PostModel>? posts,
    bool? isLoading,
    bool? isLoadingPosts,
    bool? isPrivate,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isPrivate: isPrivate ?? this.isPrivate,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  Future<void> loadProfile(String? username) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // If no username provided load current user's profile
      String targetUsername = username ?? '';
      if (targetUsername.isEmpty) {
        targetUsername = await SecureStorage.getUsername() ?? '';
      }

      if (targetUsername.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not determine user',
        );
        return;
      }

      final dio = ApiClient.instance;
      final response = await dio.get('/users/$targetUsername');
      final user = UserModel.fromJson(response.data['data']['user']);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );

      // Load posts after profile
      await loadPosts(targetUsername);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile',
      );
    }
  }

  Future<void> loadPosts(String username) async {
    state = state.copyWith(isLoadingPosts: true);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/users/$username/posts');
      final data = response.data['data'];

      if (data['private'] == true) {
        state = state.copyWith(
          isPrivate: true,
          isLoadingPosts: false,
          posts: [],
        );
        return;
      }

      final postsJson = data['posts'] as List<dynamic>;
      final posts = postsJson
          .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        posts: posts,
        isLoadingPosts: false,
        isPrivate: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPosts: false);
    }
  }

  Future<void> toggleFollow() async {
    final user = state.user;
    if (user == null) return;

    final isFollowing = user.isFollowing ?? false;

    // Optimistic update
    state = state.copyWith(
      user: user.copyWith(
        isFollowing: !isFollowing,
        followersCount: isFollowing
            ? user.followersCount - 1
            : user.followersCount + 1,
      ),
    );

    try {
      final dio = ApiClient.instance;
      if (isFollowing) {
        await dio.delete('/users/${user.id}/unfollow');
      } else {
        await dio.post('/users/${user.id}/follow');
      }
    } catch (e) {
      // Revert on failure
      state = state.copyWith(user: user);
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});