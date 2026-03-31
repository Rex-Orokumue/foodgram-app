import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;

      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserInfo(
        userId: user.id,
        username: user.username,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw Exception(_parseError(e));
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'display_name': displayName ?? username,
        },
      );

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;

      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserInfo(
        userId: user.id,
        username: user.username,
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      throw Exception(_parseError(e));
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }

  Future<void> loadCurrentUser() async {
    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/auth/me');
      final user = UserModel.fromJson(response.data['data']['user']);
      state = state.copyWith(user: user);
    } catch (e) {
      await logout();
    }
  }

  String _parseError(dynamic e) {
  // Extract message from Dio response body
  if (e is DioException) {
    final responseData = e.response?.data;
    if (responseData != null && responseData['message'] != null) {
      return responseData['message'] as String;
    }
  }

  final errorString = e.toString();
  if (errorString.contains('Invalid email or password')) {
    return 'Invalid email or password';
  }
  if (errorString.contains('already exists')) {
    return 'An account with this email already exists';
  }
  if (errorString.contains('username is already taken')) {
    return 'This username is already taken';
  }
  if (errorString.contains('SocketException') ||
      errorString.contains('Connection refused')) {
    return 'Cannot connect to server. Check your internet connection.';
  }
  return 'Something went wrong. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});