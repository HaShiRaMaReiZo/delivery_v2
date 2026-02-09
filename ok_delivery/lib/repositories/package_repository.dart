import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/package_model.dart';

class PackageRepository {
  PackageRepository(this._client);
  final ApiClient _client;

  Future<BulkPackageResponse> bulkCreate(
    List<CreatePackageModel> packages,
  ) async {
    try {
      final response = await _client.post(
        ApiEndpoints.merchantPackagesBulk,
        data: {'packages': packages.map((p) => p.toJson()).toList()},
      );

      return BulkPackageResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to create packages';
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

  Future<BulkPackageResponse> saveDraft(
    List<CreatePackageModel> packages,
  ) async {
    try {
      final response = await _client.post(
        ApiEndpoints.merchantDrafts,
        data: {'packages': packages.map((p) => p.toJson()).toList()},
      );

      // Check if response is HTML instead of JSON
      if (response.data is String) {
        final responseString = response.data as String;
        if (responseString.trim().startsWith('<!DOCTYPE') ||
            responseString.trim().startsWith('<html') ||
            responseString.contains('<html')) {
          throw Exception(
            'Server returned HTML instead of JSON. This usually means the database migrations have not been run. Please contact support or wait for the deployment to complete.',
          );
        }
      }

      // Ensure response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response format from server. Expected JSON but got: ${response.data.runtimeType}',
        );
      }

      return BulkPackageResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        // Check if response is HTML
        if (e.response?.data is String) {
          final responseString = e.response!.data as String;
          if (responseString.trim().startsWith('<!DOCTYPE') ||
              responseString.trim().startsWith('<html') ||
              responseString.contains('<html')) {
            throw Exception(
              'Server returned HTML error page. This usually means the database migrations have not been run. Please contact support.',
            );
          }
        }

        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to save drafts';
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

  Future<List<PackageModel>> getDrafts() async {
    try {
      final response = await _client.get(ApiEndpoints.merchantDrafts);

      // Handle empty list or null response
      if (response.data == null) {
        return [];
      }

      // Check if response.data is a List
      if (response.data is! List) {
        // If it's a Map, check for a 'data' key or 'packages' key
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('data') && data['data'] is List) {
            final packagesList = data['data'] as List<dynamic>;
            if (packagesList.isEmpty) {
              return [];
            }
            return packagesList
                .map((p) => PackageModel.fromJson(p as Map<String, dynamic>))
                .toList();
          } else if (data.containsKey('packages') && data['packages'] is List) {
            final packagesList = data['packages'] as List<dynamic>;
            if (packagesList.isEmpty) {
              return [];
            }
            return packagesList
                .map((p) => PackageModel.fromJson(p as Map<String, dynamic>))
                .toList();
          } else if (data.containsKey('message') &&
              data['message'].toString().contains('No valid draft packages')) {
            // Backend returned a message indicating no drafts
            return [];
          }
        }
        // If not a list and not a recognized map structure, return empty
        return [];
      }

      final packagesList = response.data as List<dynamic>;
      if (packagesList.isEmpty) {
        return [];
      }

      return packagesList
          .map((p) => PackageModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        // Check if it's a "no drafts" message - return empty list instead of error
        final errorMsg = e.response?.data?['message']?.toString() ?? '';
        if (errorMsg.contains('No valid draft packages') ||
            errorMsg.contains('No draft packages')) {
          return [];
        }

        final finalErrorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to get drafts';
        throw Exception(finalErrorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      // If it's a type error about "No valid draft packages", return empty list
      if (e.toString().contains('No valid draft packages')) {
        return [];
      }
      rethrow;
    }
  }

  Future<BulkPackageResponse> submitDrafts(List<int> packageIds) async {
    try {
      final response = await _client.post(
        ApiEndpoints.merchantDraftsSubmit,
        data: {'package_ids': packageIds},
      );

      return BulkPackageResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to submit drafts';
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PackageModel> updateDraft(
    int packageId,
    CreatePackageModel package,
  ) async {
    try {
      final packageData = package.toJson();

      // Handle image update: if packageImage is empty string, include it to delete
      // If it's null, don't include it (keep existing)
      // If it has value, it's already included in toJson()
      if (package.packageImage != null) {
        // Include it even if empty (to delete) or if it has value (to update)
        packageData['package_image'] = package.packageImage;
      }

      final response = await _client.put(
        ApiEndpoints.merchantDraftUpdate(packageId),
        data: packageData,
      );

      return PackageModel.fromJson(
        response.data['package'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to update draft';
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDraft(int packageId) async {
    try {
      await _client.delete(ApiEndpoints.merchantDraftDelete(packageId));
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to delete draft';
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PackageModel>> getPackages({int page = 1}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.merchantPackages,
        queryParameters: {'page': page},
      );

      // Handle paginated Laravel response
      List<dynamic> packagesData;
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        // Laravel pagination returns data in 'data' key
        if (dataMap.containsKey('data') && dataMap['data'] is List) {
          packagesData = dataMap['data'] as List<dynamic>;
        } else if (dataMap.containsKey('packages') &&
            dataMap['packages'] is List) {
          packagesData = dataMap['packages'] as List<dynamic>;
        } else {
          packagesData = [];
        }
      } else if (response.data is List) {
        packagesData = response.data as List<dynamic>;
      } else {
        packagesData = [];
      }

      if (packagesData.isEmpty) {
        return [];
      }

      return packagesData.map((json) {
        try {
          return PackageModel.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing package: $e');
          debugPrint('Package data: $json');
          rethrow;
        }
      }).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to fetch packages';
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      debugPrint('Error in getPackages: $e');
      rethrow;
    }
  }

  Future<LiveLocationResponse> getLiveLocation(int packageId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.merchantPackageLiveLocation(packageId),
      );

      return LiveLocationResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to fetch live location';
        throw Exception(errorMsg);
      } else {
        throw Exception(e.message ?? 'Network error occurred');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class LiveLocationResponse {
  final RiderLocation? rider;
  final PackageLocationInfo package;
  final bool isLive;
  final String? message;

  LiveLocationResponse({
    this.rider,
    required this.package,
    required this.isLive,
    this.message,
  });

  factory LiveLocationResponse.fromJson(Map<String, dynamic> json) {
    return LiveLocationResponse(
      rider: json['rider'] != null
          ? RiderLocation.fromJson(json['rider'] as Map<String, dynamic>)
          : null,
      package: PackageLocationInfo.fromJson(
        json['package'] as Map<String, dynamic>,
      ),
      isLive: json['is_live'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class RiderLocation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime? lastUpdate;

  RiderLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.lastUpdate,
  });

  static double _coordinateFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: _coordinateFromJson(json['latitude']),
      longitude: _coordinateFromJson(json['longitude']),
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'] as String).toUtc()
          : null,
    );
  }
}

class PackageLocationInfo {
  final int id;
  final String? trackingCode;
  final String status;
  final String deliveryAddress;

  PackageLocationInfo({
    required this.id,
    this.trackingCode,
    required this.status,
    required this.deliveryAddress,
  });

  factory PackageLocationInfo.fromJson(Map<String, dynamic> json) {
    return PackageLocationInfo(
      id: json['id'] as int,
      trackingCode: json['tracking_code'] as String?,
      status: json['status'] as String,
      deliveryAddress: json['delivery_address'] as String,
    );
  }
}

class BulkPackageResponse {
  final String message;
  final int createdCount;
  final int submittedCount; // For submitDrafts response
  final int failedCount;
  final List<PackageModel> packages;
  final List<PackageError> errors;
  final List<ImageUploadError>? imageUploadErrors;

  BulkPackageResponse({
    required this.message,
    required this.createdCount,
    this.submittedCount = 0,
    required this.failedCount,
    required this.packages,
    required this.errors,
    this.imageUploadErrors,
  });

  factory BulkPackageResponse.fromJson(Map<String, dynamic> json) {
    // Parse packages with error handling
    List<PackageModel> packagesList = [];
    if (json['packages'] is List<dynamic>) {
      final packagesData = json['packages'] as List<dynamic>;
      for (var p in packagesData) {
        try {
          if (p is Map<String, dynamic>) {
            packagesList.add(PackageModel.fromJson(p));
          }
        } catch (e) {
          debugPrint('Error parsing package: $e');
          debugPrint('Package data: $p');
          // Continue parsing other packages even if one fails
        }
      }
    }

    return BulkPackageResponse(
      message: json['message'] as String,
      createdCount:
          json['created_count'] as int? ?? json['submitted_count'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      packages: packagesList,
      errors:
          (json['errors'] as List<dynamic>?)
              ?.map((e) {
                try {
                  return PackageError.fromJson(e as Map<String, dynamic>);
                } catch (err) {
                  debugPrint('Error parsing error: $err');
                  return null;
                }
              })
              .whereType<PackageError>()
              .toList() ??
          [],
      imageUploadErrors: (json['image_upload_errors'] as List<dynamic>?)
          ?.map((e) {
            try {
              return ImageUploadError.fromJson(e as Map<String, dynamic>);
            } catch (err) {
              debugPrint('Error parsing image upload error: $err');
              return null;
            }
          })
          .whereType<ImageUploadError>()
          .toList(),
    );
  }
}

class PackageError {
  final int index;
  final String customerName;
  final String error;

  PackageError({
    required this.index,
    required this.customerName,
    required this.error,
  });

  factory PackageError.fromJson(Map<String, dynamic> json) {
    // Handle index as both int and string (backend might send either)
    int indexValue;
    if (json['index'] is int) {
      indexValue = json['index'] as int;
    } else if (json['index'] is String) {
      indexValue = int.tryParse(json['index'] as String) ?? 0;
    } else {
      indexValue = 0;
    }

    return PackageError(
      index: indexValue,
      customerName:
          json['customer_name'] as String? ??
          json['customerName'] as String? ??
          'Unknown',
      error: json['error'] as String,
    );
  }
}

class ImageUploadError {
  final String? trackingCode; // May be null for drafts
  final String? customerName; // For drafts
  final int? index; // For drafts
  final String error;

  ImageUploadError({
    this.trackingCode,
    this.customerName,
    this.index,
    required this.error,
  });

  factory ImageUploadError.fromJson(Map<String, dynamic> json) {
    return ImageUploadError(
      trackingCode: json['tracking_code'] as String?,
      customerName: json['customer_name'] as String?,
      index: json['index'] is int
          ? json['index'] as int
          : json['index'] is String
          ? int.tryParse(json['index'] as String)
          : null,
      error: json['error'] as String,
    );
  }
}
