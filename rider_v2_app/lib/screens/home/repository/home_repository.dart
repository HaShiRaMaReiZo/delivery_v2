import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/package_model.dart';

class HomeRepository {
  HomeRepository(this._client);
  final ApiClient _client;

  /// Get all packages assigned to the rider (active packages only)
  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await _client.get(ApiEndpoints.riderPackages);

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
            'Failed to fetch packages',
      );
    } catch (e) {
      throw Exception('Error loading packages: ${e.toString()}');
    }
  }

  /// Get delivered packages for the rider (includes delivered status)
  Future<List<PackageModel>> getDeliveredPackages() async {
    try {
      final response = await _client.get(
        ApiEndpoints.riderPackages,
        queryParameters: {'include_delivered': 'true'},
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

      // Filter only delivered packages
      final deliveredPackages = packagesList
          .where((json) => json['status'] == 'delivered')
          .map((json) => PackageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return deliveredPackages;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to fetch delivered packages',
      );
    } catch (e) {
      throw Exception('Error loading delivered packages: ${e.toString()}');
    }
  }
}
