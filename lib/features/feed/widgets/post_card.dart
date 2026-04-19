import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/post.model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onStoryTap;
  final bool hasStory;
  final bool hasUnviewedStory;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onTap,
    required this.onProfileTap,
    this.onStoryTap,
    this.hasStory = false,
    this.hasUnviewedStory = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (post.hasMedia) _buildMedia(),
            _buildActions(),
            if (post.caption != null && post.caption!.isNotEmpty)
              _buildCaption(),
            _buildMeta(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          // Avatar with optional story ring
          GestureDetector(
            onTap: onStoryTap ?? onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory && hasUnviewedStory
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasStory && !hasUnviewedStory
                    ? AppColors.textHint
                    : Colors.transparent,
              ),
              padding: EdgeInsets.all(hasStory ? 2 : 0),
              child: CircleAvatar(
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
            ),
          ),
          const SizedBox(width: 10),

          // Name and location
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

          // Post type badge
          if (post.isRecipe || post.isMenuItem)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: post.isRecipe
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                post.isRecipe ? 'Recipe' : 'Order',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: post.isRecipe
                      ? AppColors.primary
                      : AppColors.success,
                ),
              ),
            ),

          const SizedBox(width: 8),

          const Icon(
            Icons.more_horiz,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final firstMedia = post.media.first;

    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: firstMedia.isVideo
            ? (firstMedia.thumbnailUrl ?? firstMedia.mediaUrl)
            : firstMedia.mediaUrl,
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

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: onLike,
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

          // Comment button
          GestureDetector(
            onTap: onTap,
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textPrimary,
              size: 24,
            ),
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

          // Price tag if for sale
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

          // Save button
          const SizedBox(width: 8),
          Icon(
            post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
            color: post.savedByMe
                ? AppColors.primary
                : AppColors.textPrimary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
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
                height: 1.4,
              ),
            ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMeta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        children: [
          if (post.cuisineTag != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                post.cuisineTag!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Text(
            _timeAgo(post.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}