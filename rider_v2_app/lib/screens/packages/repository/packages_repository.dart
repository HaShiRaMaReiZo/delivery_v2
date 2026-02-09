import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../models/package_model.dart';

class PackagesRepository {
  PackagesRepository(this._client);
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

  /// Confirm pickup for all packages from a merchant
  Future<void> confirmPickupByMerchant(int merchantId) async {
    try {
      await _client.post(ApiEndpoints.riderConfirmPickup(merchantId));
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to confirm pickup',
      );
    } catch (e) {
      throw Exception('Error confirming pickup: ${e.toString()}');
    }
  }

  /// Receive package from office (for delivery)
  Future<PackageModel> receiveFromOffice(int packageId, {String? notes}) async {
    try {
      final response = await _client.post(
        ApiEndpoints.riderReceiveFromOffice(packageId),
        data: notes != null ? {'notes': notes} : null,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final packageData = response.data is Map
          ? (response.data['package'] ?? response.data)
          : response.data;

      return PackageModel.fromJson(packageData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to receive package from office',
      );
    } catch (e) {
      throw Exception('Error receiving package: ${e.toString()}');
    }
  }

  /// Start delivery
  Future<PackageModel> startDelivery(int packageId) async {
    try {
      final response = await _client.post(ApiEndpoints.riderStart(packageId));

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final packageData = response.data is Map
          ? (response.data['package'] ?? response.data)
          : response.data;

      return PackageModel.fromJson(packageData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to start delivery',
      );
    } catch (e) {
      throw Exception('Error starting delivery: ${e.toString()}');
    }
  }

  /// Upload delivery proof and mark as delivered
  Future<PackageModel> uploadProof(
    int packageId, {
    File? photo,
    String? signature,
    double? latitude,
    double? longitude,
    String? deliveredToName,
    String? deliveredToPhone,
    String? notes,
  }) async {
    try {
      final formData = FormData();

      if (photo != null) {
        formData.files.add(
          MapEntry('proof_data', await MultipartFile.fromFile(photo.path)),
        );
        formData.fields.add(const MapEntry('proof_type', 'photo'));
      } else if (signature != null) {
        formData.fields.add(const MapEntry('proof_type', 'signature'));
        formData.fields.add(MapEntry('proof_data', signature));
      }

      if (latitude != null) {
        formData.fields.add(MapEntry('delivery_latitude', latitude.toString()));
      }
      if (longitude != null) {
        formData.fields.add(
          MapEntry('delivery_longitude', longitude.toString()),
        );
      }
      if (deliveredToName != null) {
        formData.fields.add(MapEntry('delivered_to_name', deliveredToName));
      }
      if (deliveredToPhone != null) {
        formData.fields.add(MapEntry('delivered_to_phone', deliveredToPhone));
      }
      if (notes != null) {
        formData.fields.add(MapEntry('notes', notes));
      }

      final response = await _client.raw.post(
        ApiEndpoints.riderProof(packageId),
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server: empty response');
      }

      // Handle different response formats
      Map<String, dynamic>? packageData;
      
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        packageData = data['package'] as Map<String, dynamic>? ?? data;
      } else if (response.data is String) {
        // If response is a string, try to parse it as JSON
        try {
          final parsed = jsonDecode(response.data as String);
          if (parsed is Map<String, dynamic>) {
            packageData = parsed['package'] as Map<String, dynamic>? ?? parsed;
          }
        } catch (e) {
          throw Exception('Invalid response format: ${response.data}');
        }
      }

      if (packageData == null) {
        throw Exception('Invalid response format: expected package data but got ${response.data.runtimeType}');
      }

      return PackageModel.fromJson(packageData);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to upload proof',
      );
    } catch (e) {
      throw Exception('Error uploading proof: ${e.toString()}');
    }
  }

  /// Collect COD and mark as delivered
  Future<PackageModel> collectCod(
    int packageId, {
    required double amount,
    File? collectionProof,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('amount', amount.toString()));

      if (collectionProof != null) {
        formData.files.add(
          MapEntry(
            'collection_proof',
            await MultipartFile.fromFile(collectionProof.path),
          ),
        );
      }

      final response = await _client.raw.post(
        ApiEndpoints.riderCod(packageId),
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final packageData = response.data is Map
          ? (response.data['package'] ?? response.data)
          : response.data;

      return PackageModel.fromJson(packageData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to collect COD',
      );
    } catch (e) {
      throw Exception('Error collecting COD: ${e.toString()}');
    }
  }

  /// Contact customer
  Future<PackageModel> contactCustomer(
    int packageId, {
    required String contactResult, // 'success' or 'failed'
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.riderContact(packageId),
        data: {
          'contact_result': contactResult,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final packageData = response.data is Map
          ? (response.data['package'] ?? response.data)
          : response.data;

      return PackageModel.fromJson(packageData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to record contact',
      );
    } catch (e) {
      throw Exception('Error recording contact: ${e.toString()}');
    }
  }

  /// Update package status (generic)
  Future<PackageModel> updateStatus(
    int packageId, {
    required String status,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client.put(
        ApiEndpoints.riderStatus(packageId),
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final packageData = response.data is Map
          ? (response.data['package'] ?? response.data)
          : response.data;

      return PackageModel.fromJson(packageData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to update status',
      );
    } catch (e) {
      throw Exception('Error updating status: ${e.toString()}');
    }
  }
}
