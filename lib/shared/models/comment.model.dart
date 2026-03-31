class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String body;
  final int likesCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool? isVerified;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.body,
    required this.likesCount,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isVerified,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      body: json['body'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool?,
    );
  }

  bool get isReply => parentId != null;
  bool get isTopLevel => parentId == null;
  String get authorName => displayName ?? username ?? 'Unknown';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo';
    return '${(difference.inDays / 365).floor()}y';
  }
}