import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../providers/post.provider.dart';
import '../../../shared/models/comment.model.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(postDetailProvider.notifier).loadPost(widget.postId),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    _commentController.clear();

    await ref.read(postDetailProvider.notifier).addComment(
          widget.postId,
          body,
        );

    setState(() => _isSubmittingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post'),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null
              ? Center(child: Text(state.error!))
              : state.post == null
                  ? const Center(child: Text('Post not found'))
                  : Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Post header
                              SliverToBoxAdapter(
                                child: _buildPostHeader(state),
                              ),

                              // Post media
                              if (state.post!.hasMedia)
                                SliverToBoxAdapter(
                                  child: _buildMedia(state),
                                ),

                              // Post actions
                              SliverToBoxAdapter(
                                child: _buildActions(state),
                              ),

                              // Caption
                              if (state.post!.caption != null)
                                SliverToBoxAdapter(
                                  child: _buildCaption(state),
                                ),

                              // View Recipe button for recipe posts
                              if (state.post!.isRecipe)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 8, 12, 8),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () => context.push(
                                          '/recipe/${widget.postId}',
                                        ),
                                        icon: const Icon(
                                          Icons.restaurant_menu,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'View Full Recipe',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Comments header
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 8),
                                  child: Text(
                                    'Comments (${state.post!.commentsCount})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // Comments
                              state.isLoadingComments
                                  ? const SliverToBoxAdapter(
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : state.comments.isEmpty
                                      ? const SliverToBoxAdapter(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Center(
                                              child: Text(
                                                'No comments yet. Be the first!',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SliverList(
                                          delegate:
                                              SliverChildBuilderDelegate(
                                            (context, index) =>
                                                _buildComment(
                                              state.comments[index],
                                            ),
                                            childCount: state.comments.length,
                                          ),
                                        ),
                            ],
                          ),
                        ),

                        // Comment input
                        _buildCommentInput(),
                      ],
                    ),
    );
  }

  Widget _buildPostHeader(PostDetailState state) {
    final post = state.post!;
    return GestureDetector(
      onTap: () => context.push('/profile/${post.username}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: post.avatarUrl != null
                  ? CachedNetworkImageProvider(post.avatarUrl!)
                  : null,
              child: post.avatarUrl == null
                  ? Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (post.isVerified == true) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  if (post.locationName != null)
                    Text(
                      post.locationName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.more_horiz,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(PostDetailState state) {
    final post = state.post!;
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: post.media.first.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surfaceVariant,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textHint,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(PostDetailState state) {
    final post = state.post!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(postDetailProvider.notifier).likePost(widget.postId),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(post.likedByMe),
                color: post.likedByMe ? Colors.red : AppColors.textPrimary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${post.likesCount}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.textPrimary,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.commentsCount}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (post.isForSale && post.price != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.formattedPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaption(PostDetailState state) {
    final post = state.post!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${post.authorName} ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: post.caption,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: comment.avatarUrl != null
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.authorName} ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: comment.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.timeAgo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          _isSubmittingComment
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : TextButton(
                  onPressed: _submitComment,
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}