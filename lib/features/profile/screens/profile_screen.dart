import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../providers/profile.provider.dart';
import '../../../features/auth/providers/auth.provider.dart';
import '../../../shared/models/post.model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? username;

  const ProfileScreen({super.key, this.username});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileProvider.notifier).loadProfile(widget.username),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          profileState.user?.username ?? 'Profile',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (profileState.user?.isOwnProfile == true)
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
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : profileState.error != null
              ? Center(child: Text(profileState.error!))
              : profileState.user == null
                  ? const Center(child: Text('User not found'))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(profileProvider.notifier)
                          .loadProfile(widget.username),
                      color: AppColors.primary,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildProfileHeader(profileState),
                          ),
                          if (profileState.isPrivate)
                            SliverToBoxAdapter(
                              child: _buildPrivateAccount(),
                            )
                          else if (profileState.isLoadingPosts)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 1.5,
                                mainAxisSpacing: 1.5,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildPostThumbnail(
                                  profileState.posts[index],
                                ),
                                childCount: profileState.posts.length,
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader(ProfileState profileState) {
    final user = profileState.user!;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.surfaceVariant,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName![0].toUpperCase()
                            : user.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 24),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('Posts', user.postsCount),
                    _buildStat('Followers', user.followersCount),
                    _buildStat('Following', user.followingCount),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Name
          Row(
            children: [
              Text(
                user.displayName ?? user.username,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
              if (user.isBusiness) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Business',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          if (user.isOwnProfile == true)
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Edit profile',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(profileProvider.notifier).toggleFollow(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isFollowing == true
                            ? AppColors.surfaceVariant
                            : AppColors.primary,
                        foregroundColor: user.isFollowing == true
                            ? AppColors.textPrimary
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        user.followRequested == true
                            ? 'Requested'
                            : user.isFollowing == true
                                ? 'Following'
                                : 'Follow',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildPostThumbnail(PostModel post) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: post.hasMedia
          ? CachedNetworkImage(
              imageUrl: post.media.first.isVideo
                  ? (post.media.first.thumbnailUrl ?? post.media.first.mediaUrl)
                  : post.media.first.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surfaceVariant,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
            )
          : Container(
              color: AppColors.surfaceVariant,
              child: Center(
                child: Text(
                  post.caption?.substring(
                        0,
                        post.caption!.length > 50
                            ? 50
                            : post.caption!.length,
                      ) ??
                      '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
    );
  }

  Widget _buildPrivateAccount() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'This account is private',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Follow this account to see their posts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}