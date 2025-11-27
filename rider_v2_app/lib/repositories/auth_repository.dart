import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.data == null) {
        throw Exception('Empty response from server');
      }

      final authResponse = AuthResponseModel.fromJson(response.data);

      // Store token
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, authResponse.token);
        if (kDebugMode) {
          print('AuthRepository: Token saved successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AuthRepository: ERROR saving token: $e');
        }
        throw Exception('Failed to save authentication token: $e');
      }

      // Update API client token immediately
      _client.updateToken(authResponse.token);

      if (kDebugMode) {
        print('AuthRepository: Login successful, token updated in API client');
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Login failed: ${e.response?.statusCode}';
        throw Exception(errorMsg);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);

    try {
      await _client
          .post(ApiEndpoints.logout)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Logout timeout'),
          );
    } catch (e) {
      // Ignore errors - token is already cleared
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _client.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final user = await getCurrentUser();
      return user != null && user.role == 'rider';
    } catch (e) {
      await logout();
      return false;
    }
  }
}
