import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import 'location_socket_service.dart';

class LocationService {
  LocationService(this._client, {int? riderId}) {
    _socketService = LocationSocketService();
    _riderId = riderId;
  }

  final ApiClient _client;
  LocationSocketService? _socketService;
  int? _riderId;

  /// Set the rider ID (should be called after login)
  void setRiderId(int riderId) {
    _riderId = riderId;
    _socketService?.connect(riderId: riderId);
  }

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
          'LocationService: Sending location update via Socket.io (rider_id: $_riderId)',
        );
        debugPrint(
          'LocationService: Data: lat=$latitude, lng=$longitude, packageId=$packageId',
        );
        debugPrint('========================================');
      }

      // If rider_id is not set, try to get it from API first
      // IMPORTANT: Use rider.id (from riders table) not user.id (from users table)
      if (_riderId == null) {
        try {
          final response = await _client.get(ApiEndpoints.me);
          if (response.data['user'] != null &&
              response.data['user']['rider'] != null &&
              response.data['user']['rider']['id'] != null) {
            _riderId = response.data['user']['rider']['id'] as int;
            _socketService?.connect(riderId: _riderId!);
            if (kDebugMode) {
              debugPrint(
                'LocationService: Retrieved rider_id from API: $_riderId (user_id=${response.data['user']['id']})',
              );
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                'LocationService: ⚠️ Rider data not found in API response. user.id=${response.data['user']?['id']}',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('LocationService: Could not get rider_id from API: $e');
          }
        }
      }

      // Send via Socket.io (direct to Node.js server)
      if (_riderId != null && _socketService != null) {
        _socketService!.sendLocationUpdate(
          riderId: _riderId!,
          latitude: latitude,
          longitude: longitude,
          packageId: packageId,
          speed: speed,
          heading: heading,
        );
      } else {
        if (kDebugMode) {
          debugPrint(
            'LocationService: Cannot send location - rider_id is null',
          );
        }
        throw Exception('Rider ID not available');
      }

      if (kDebugMode) {
        debugPrint(
          'Location update sent successfully via Socket.io: $latitude, $longitude',
        );
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

  void dispose() {
    _socketService?.disconnect();
    _socketService = null;
  }
}
