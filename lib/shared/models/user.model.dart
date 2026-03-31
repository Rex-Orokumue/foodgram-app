class UserModel {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String accountType;
  final bool isVerified;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final bool? isFollowing;
  final bool? followRequested;
  final bool? isOwnProfile;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.accountType,
    required this.isVerified,
    required this.isPrivate,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
    this.isFollowing,
    this.followRequested,
    this.isOwnProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      accountType: json['account_type'] as String? ?? 'personal',
      isVerified: json['is_verified'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isFollowing: json['is_following'] as bool?,
      followRequested: json['follow_requested'] as bool?,
      isOwnProfile: json['is_own_profile'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'account_type': accountType,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'created_at': createdAt.toIso8601String(),
      'is_following': isFollowing,
      'follow_requested': followRequested,
      'is_own_profile': isOwnProfile,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowing,
    bool? followRequested,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      accountType: accountType,
      isVerified: isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt,
      isFollowing: isFollowing ?? this.isFollowing,
      followRequested: followRequested ?? this.followRequested,
      isOwnProfile: isOwnProfile,
    );
  }

  bool get isBusiness => accountType == 'business';
}