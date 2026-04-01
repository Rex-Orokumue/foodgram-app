import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../providers/story_feed.provider.dart';

class StoryTray extends ConsumerWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyFeedProvider);

    return Container(
      height: 100,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: state.groups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton(context);
          }
          final group = state.groups[index - 1];
          return _buildStoryBubble(context, group);
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push('/create-post'),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your story',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBubble(BuildContext context, dynamic group) {
    final hasUnviewed = group.hasUnviewed as bool;

    return GestureDetector(
      onTap: () => context.push('/stories/${group.userId}'),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasUnviewed ? null : AppColors.textHint,
              ),
              padding: const EdgeInsets.all(2.5),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: group.avatarUrl != null
                    ? CachedNetworkImageProvider(group.avatarUrl as String)
                    : null,
                child: group.avatarUrl == null
                    ? Text(
                        (group.authorName as String).isNotEmpty
                            ? (group.authorName as String)[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.authorName as String,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}