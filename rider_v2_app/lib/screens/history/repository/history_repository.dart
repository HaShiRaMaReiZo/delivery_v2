import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/package_model.dart';

class HistoryRepository {
  HistoryRepository(this._client);
  final ApiClient _client;

  /// Get delivered packages for the current month only
  Future<List<PackageModel>> getHistory(int riderId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.riderPackagesHistory(riderId),
      );

      if (response.data == null) {
        return [];
      }

      // Handle both list and wrapped response
      List<dynamic> packagesList;
      if (response.data is List) {
        packagesList = response.data as List<dynamic>;
      } else if (response.data is Map && response.data['data'] != null) {
        packagesList = response.data['data'] as List<dynamic>;
      } else {
        return [];
      }

      return packagesList
          .map((json) => PackageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to fetch history',
      );
    } catch (e) {
      throw Exception('Error loading history: ${e.toString()}');
    }
  }
}
