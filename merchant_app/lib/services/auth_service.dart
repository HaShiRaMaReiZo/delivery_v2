import '../core/api_client.dart';
import '../core/api_endpoints.dart';

class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.raw.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _client.raw.get(ApiEndpoints.me);
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _client.raw.post(ApiEndpoints.logout);
  }
}
