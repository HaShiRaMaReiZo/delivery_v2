import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class LocationService {
  LocationService(this._client);
  final ApiClient _client;

  Future<void> update({
    required double latitude,
    required double longitude,
    int? packageId,
    double? speed,
    double? heading,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('LocationService: update() called');
        debugPrint(
          'LocationService: Sending location update to ${ApiEndpoints.riderLocation}',
        );
        debugPrint(
          'LocationService: Data: lat=$latitude, lng=$longitude, packageId=$packageId',
        );
        debugPrint('========================================');
      }

      await _client.post(
        ApiEndpoints.riderLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (packageId != null) 'package_id': packageId,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
        },
      );

      if (kDebugMode) {
        debugPrint('Location update sent successfully: $latitude, $longitude');
      }
    } catch (e, stackTrace) {
      // Log error but don't throw - location tracking should continue
      if (kDebugMode) {
        debugPrint('LocationService: Location update failed: $e');
        debugPrint('LocationService: Stack trace: $stackTrace');
      }
      // Re-throw so the bloc can handle it
      rethrow;
    }
  }
}
