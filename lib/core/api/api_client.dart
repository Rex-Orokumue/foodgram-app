import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://foodgram-backend-production.up.railway.app/api';
  // Replace with your actual Railway URL

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // JWT interceptor — automatically attaches token to every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Token expired — clear storage and force re-login
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'user_id');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}