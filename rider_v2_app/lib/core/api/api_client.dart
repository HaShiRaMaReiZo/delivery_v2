import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  factory ApiClient.create({required String baseUrl, String? token}) {
    // Function to get token dynamically from SharedPreferences
    Future<String?> getToken() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        const tokenKey = 'auth_token';
        final token = prefs.getString(tokenKey);
        if (kDebugMode && token != null) {
          print('ApiClient: Token found in SharedPreferences');
        }
        return token;
      } catch (e) {
        if (kDebugMode) {
          print('ApiClient: SharedPreferences not available yet: $e');
        }
        return null;
      }
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        contentType: 'application/json',
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    // Add request interceptor to handle token dynamically
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final currentToken = token ?? await getToken();
          if (currentToken != null) {
            options.headers['Authorization'] = 'Bearer $currentToken';
          }
          handler.next(options);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return ApiClient(dio);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // Expose raw dio for advanced usage
  Dio get raw => _dio;

  // Update token method
  void updateToken(String? newToken) {
    if (newToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $newToken';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }
}
