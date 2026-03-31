class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime expiresAt;
  final DateTime createdAt;

  // Joined fields
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool? isVerified;

  // Interaction state
  final bool viewedByMe;
  final int? viewCount;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.expiresAt,
    required this.createdAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isVerified,
    required this.viewedByMe,
    this.viewCount,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      caption: json['caption'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool?,
      viewedByMe: json['viewed_by_me'] as bool? ?? false,
      viewCount: json['view_count'] != null
          ? int.tryParse(json['view_count'].toString())
          : null,
    );
  }

  bool get isVideo => mediaType == 'video';
  bool get isPhoto => mediaType == 'photo';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get authorName => displayName ?? username ?? 'Unknown';
}

class StoryGroupModel {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isVerified;
  final bool hasUnviewed;
  final List<StoryModel> stories;

  const StoryGroupModel({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.isVerified,
    required this.hasUnviewed,
    required this.stories,
  });

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    final storiesList = (json['stories'] as List<dynamic>? ?? [])
        .map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return StoryGroupModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      hasUnviewed: json['has_unviewed'] as bool? ?? false,
      stories: storiesList,
    );
  }

  String get authorName => displayName ?? username;
  int get storyCount => stories.length;
}