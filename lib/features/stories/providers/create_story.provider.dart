import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
//import 'dart:io';
import '../../../core/api/api_client.dart';

class CreateStoryState {
  final XFile? selectedMedia;
  final bool isVideo;
  final bool isLoading;
  final String? error;

  const CreateStoryState({
    this.selectedMedia,
    this.isVideo = false,
    this.isLoading = false,
    this.error,
  });

  CreateStoryState copyWith({
    XFile? selectedMedia,
    bool? isVideo,
    bool? isLoading,
    String? error,
  }) {
    return CreateStoryState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      isVideo: isVideo ?? this.isVideo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasMedia => selectedMedia != null;
}

class CreateStoryNotifier extends Notifier<CreateStoryState> {
  @override
  CreateStoryState build() {
    return const CreateStoryState();
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      state = state.copyWith(
        selectedMedia: file,
        isVideo: false,
      );
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) {
      state = state.copyWith(
        selectedMedia: file,
        isVideo: true,
        error: null,
      );
    }
  }

  void clearMedia() {
    state = const CreateStoryState();
  }

  Future<bool> createStory({String? caption}) async {
    if (state.selectedMedia == null) {
      state = state.copyWith(error: 'Please select a photo or video');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1 — Upload media to R2
      final mediaDio = ApiClient.mediaInstance;
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          state.selectedMedia!.path,
          filename: state.selectedMedia!.name,
        ),
      });

      final uploadResponse = await mediaDio.post(
        '/media/story',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final mediaUrl =
          uploadResponse.data['data']['media_url'] as String;
      final mediaType =
          uploadResponse.data['data']['media_type'] as String;

      // Step 2 — Create the story with the uploaded URL
      final dio = ApiClient.instance;
      await dio.post(
        '/stories',
        data: {
          'media_url': mediaUrl,
          'media_type': mediaType,
          'caption': caption?.trim().isEmpty == true ? null : caption?.trim(),
        },
      );

      state = const CreateStoryState();
      return true;
    } catch (e) {
      debugPrint('Create story failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create story. Please try again.',
      );
      return false;
    }
  }
}

final createStoryProvider =
    NotifierProvider<CreateStoryNotifier, CreateStoryState>(() {
  return CreateStoryNotifier();
});