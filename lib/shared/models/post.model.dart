class PostMedia {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final int displayOrder;
  final String? thumbnailUrl;

  const PostMedia({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.displayOrder,
    this.thumbnailUrl,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  bool get isVideo => mediaType == 'video';
  bool get isPhoto => mediaType == 'photo';
}

class PostModel {
  final String id;
  final String userId;
  final String? caption;
  final String postType;
  final String? cuisineTag;
  final String? locationName;
  final bool isForSale;
  final double? price;
  final int likesCount;
  final int commentsCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields from users table
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool? isVerified;

  // Media
  final List<PostMedia> media;

  // Interaction state
  final bool likedByMe;
  final bool savedByMe;

  const PostModel({
    required this.id,
    required this.userId,
    this.caption,
    required this.postType,
    this.cuisineTag,
    this.locationName,
    required this.isForSale,
    this.price,
    required this.likesCount,
    required this.commentsCount,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isVerified,
    required this.media,
    required this.likedByMe,
    required this.savedByMe,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? [])
        .map((m) => PostMedia.fromJson(m as Map<String, dynamic>))
        .toList();

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caption: json['caption'] as String?,
      postType: json['post_type'] as String? ?? 'regular',
      cuisineTag: json['cuisine_tag'] as String?,
      locationName: json['location_name'] as String?,
      isForSale: json['is_for_sale'] as bool? ?? false,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool?,
      media: mediaList,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      savedByMe: json['saved_by_me'] as bool? ?? false,
    );
  }

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
    bool? savedByMe,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      caption: caption,
      postType: postType,
      cuisineTag: cuisineTag,
      locationName: locationName,
      isForSale: isForSale,
      price: price,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isVerified: isVerified,
      media: media,
      likedByMe: likedByMe ?? this.likedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
    );
  }

  bool get isRecipe => postType == 'recipe';
  bool get isMenuItem => postType == 'menu_item';
  bool get hasMedia => media.isNotEmpty;
  bool get hasVideo => media.any((m) => m.isVideo);

  String get authorName => displayName ?? username ?? 'Unknown';

  String get formattedPrice {
    if (price == null) return '';
    return '₦${price!.toStringAsFixed(0)}';
  }
}