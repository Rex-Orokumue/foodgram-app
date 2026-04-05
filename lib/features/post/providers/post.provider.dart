import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/post.model.dart';
import '../../../shared/models/comment.model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CreatePostState {
  final List<XFile> selectedMedia;
  final bool isLoading;
  final String? error;

  const CreatePostState({
    this.selectedMedia = const [],
    this.isLoading = false,
    this.error,
  });

  CreatePostState copyWith({
    List<XFile>? selectedMedia,
    bool? isLoading,
    String? error,
  }) {
    return CreatePostState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() {
    return const CreatePostState();
  }

  Future<void> pickMedia() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      state = state.copyWith(selectedMedia: files);
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      state = state.copyWith(selectedMedia: [file]);
    }
  }

  void removeMedia(int index) {
    final updated = [...state.selectedMedia];
    updated.removeAt(index);
    state = state.copyWith(selectedMedia: updated);
  }

  Future<bool> createPost({
    required String? caption,
    required String postType,
    String? cuisineTag,
    String? locationName,
    bool isForSale = false,
    double? price,
  }) async {
    if (caption == null || caption.trim().isEmpty) {
      state = state.copyWith(error: 'Please add a caption');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;

      // Create the post first
      final response = await dio.post(
        '/posts',
        data: {
          'caption': caption.trim(),
          'post_type': postType,
          'cuisine_tag': cuisineTag,
          'location_name': locationName,
          'is_for_sale': isForSale,
          'price': price,
        },
      );

      final postId = response.data['data']['post']['id'] as String;

      // Upload media if any
      if (state.selectedMedia.isNotEmpty) {
        await _uploadMedia(postId);
      }

      state = state.copyWith(
        isLoading: false,
        selectedMedia: [],
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create post. Please try again.',
      );
      return false;
    }
  }

  Future<void> _uploadMedia(String postId) async {
    try {
      final dio = ApiClient.mediaInstance;

      final formData = FormData.fromMap({
        'postId': postId,
        'media': await Future.wait(
          state.selectedMedia.map(
            (file) async => await MultipartFile.fromFile(
              file.path,
              filename: file.name,
            ),
          ),
        ),
      });

      await dio.post(
        '/media/post',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      debugPrint('Media upload failed: $e');
    }
  }

  void reset() {
    state = const CreatePostState();
  }
}

class PostDetailState {
  final PostModel? post;
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isLoadingComments;
  final String? error;

  const PostDetailState({
    this.post,
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingComments = false,
    this.error,
  });

  PostDetailState copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isLoadingComments,
    String? error,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      error: error ?? this.error,
    );
  }
}

class PostDetailNotifier extends Notifier<PostDetailState> {
  @override
  PostDetailState build() {
    return const PostDetailState();
  }

  Future<void> loadPost(String postId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/posts/$postId');
      final post = PostModel.fromJson(response.data['data']['post']);

      state = state.copyWith(
        post: post,
        isLoading: false,
      );

      await loadComments(postId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load post',
      );
    }
  }

  Future<void> loadComments(String postId) async {
    state = state.copyWith(isLoadingComments: true);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/posts/$postId/comments');
      final commentsJson = response.data['data']['comments'] as List<dynamic>;
      final comments = commentsJson
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        comments: comments,
        isLoadingComments: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingComments: false);
    }
  }

  Future<void> addComment(String postId, String body) async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.post(
        '/posts/$postId/comments',
        data: {'body': body},
      );

      final comment = CommentModel.fromJson(
        response.data['data']['comment'],
      );

      state = state.copyWith(
        comments: [comment, ...state.comments],
        post: state.post?.copyWith(
          commentsCount: (state.post?.commentsCount ?? 0) + 1,
        ),
      );
    } catch (e) {
      // Comment failed silently
    }
  }

  Future<void> likePost(String postId) async {
    final post = state.post;
    if (post == null) return;

    final updatedPost = post.copyWith(
      likedByMe: !post.likedByMe,
      likesCount: post.likedByMe
          ? post.likesCount - 1
          : post.likesCount + 1,
    );

    state = state.copyWith(post: updatedPost);

    try {
      final dio = ApiClient.instance;
      if (updatedPost.likedByMe) {
        await dio.post('/posts/$postId/like');
      } else {
        await dio.delete('/posts/$postId/like');
      }
    } catch (e) {
      state = state.copyWith(post: post);
    }
  }
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(() {
  return CreatePostNotifier();
});

final postDetailProvider =
    NotifierProvider<PostDetailNotifier, PostDetailState>(() {
  return PostDetailNotifier();
});