import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/post.model.dart';

class FeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    return const FeedState();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get(
        '/posts/feed',
        queryParameters: {'page': 1, 'limit': 20},
      );

      final postsJson = response.data['data']['posts'] as List<dynamic>;
      final posts = postsJson
          .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final pagination = response.data['data']['pagination'];

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        currentPage: 1,
        hasMore: pagination['hasMore'] as bool,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feed',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final dio = ApiClient.instance;
      final nextPage = state.currentPage + 1;
      final response = await dio.get(
        '/posts/feed',
        queryParameters: {'page': nextPage, 'limit': 20},
      );

      final postsJson = response.data['data']['posts'] as List<dynamic>;
      final newPosts = postsJson
          .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
          .toList();

      final pagination = response.data['data']['pagination'];

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: pagination['hasMore'] as bool,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> likePost(String postId) async {
    // Optimistic update
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final updatedPost = post.copyWith(
      likedByMe: !post.likedByMe,
      likesCount: post.likedByMe
          ? post.likesCount - 1
          : post.likesCount + 1,
    );

    final updatedPosts = [...state.posts];
    updatedPosts[index] = updatedPost;
    state = state.copyWith(posts: updatedPosts);

    // API call
    try {
      final dio = ApiClient.instance;
      if (updatedPost.likedByMe) {
        await dio.post('/posts/$postId/like');
      } else {
        await dio.delete('/posts/$postId/like');
      }
    } catch (e) {
      // Revert on failure
      final revertedPosts = [...state.posts];
      revertedPosts[index] = post;
      state = state.copyWith(posts: revertedPosts);
    }
  }

  Future<void> refresh() async {
    await loadFeed();
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});