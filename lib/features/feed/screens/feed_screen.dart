import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../providers/feed.provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_tray.dart';
import '../../../features/auth/providers/auth.provider.dart';
import '../providers/story_feed.provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  bool _storiesLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(feedProvider.notifier).loadFeed();
      if (!_storiesLoaded) {
        _storiesLoaded = true;
        ref.read(storyFeedProvider.notifier).loadStories();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(feedProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'FoodGram',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) router.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(feedProvider.notifier).refresh();
          await ref.read(storyFeedProvider.notifier).loadStories();
        },
        color: AppColors.primary,
        child: feedState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : feedState.error != null
                ? _buildError(feedState.error!)
                : feedState.posts.isEmpty
                    ? _buildEmptyFeed()
                    : CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(child: StoryTray()),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == feedState.posts.length) {
                                  return feedState.isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                color: AppColors.primary),
                                          ),
                                        )
                                      : const SizedBox(height: 80);
                                }
                                final post = feedState.posts[index];
                                final storyState = ref.watch(storyFeedProvider);
                                final hasStory = storyState.groups
                                        .any((g) => g.userId == post.userId) ||
                                    storyState.ownStories?.userId == post.userId;
                                final hasUnviewedStory = storyState.groups
                                        .where((g) => g.userId == post.userId)
                                        .any((g) => g.hasUnviewed) ||
                                    (storyState.ownStories?.userId == post.userId &&
                                        (storyState.ownStories?.hasUnviewed ?? false));
                                return PostCard(
                                  post: post,
                                  onLike: () => ref
                                      .read(feedProvider.notifier)
                                      .likePost(post.id),
                                  onTap: () => context.push('/post/${post.id}'),
                                  onProfileTap: () =>
                                      context.push('/profile/${post.username}'),
                                  onStoryTap: () =>
                                      context.push('/stories/${post.userId}'),
                                  hasStory: hasStory,
                                  hasUnviewedStory: hasUnviewedStory,
                                );
                              },
                              childCount: feedState.posts.length + 1,
                            ),
                          ),
                        ],
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(feedProvider.notifier).loadFeed(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Your feed is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Follow people to see their food posts here',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
            child: const Text('Discover people'),
          ),
        ],
      ),
    );
  }
}
