import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/api/api_endpoints.dart';

/// Service for sending location updates directly to Node.js Socket.io server
class LocationSocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  int? _riderId;

  bool get isConnected => _isConnected;

  /// Connect to the location tracker server
  Future<void> connect({required int riderId}) async {
    if (_isConnecting || (_isConnected && _riderId == riderId)) {
      return;
    }

    _riderId = riderId;
    _isConnecting = true;

    try {
      if (kDebugMode) {
        debugPrint(
          'LocationSocketService: Connecting to ${ApiEndpoints.locationTrackerUrl}',
        );
      }

      _socket?.disconnect();
      _socket?.dispose();

      _socket = io.io(
        ApiEndpoints.locationTrackerUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(999999)
            .build(),
      );

      // Connection events
      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        if (kDebugMode) {
          debugPrint('LocationSocketService: Connected to location tracker');
        }

        // Register as rider
        _socket!.emit('join:rider', {'rider_id': riderId});
      });

      _socket!.onConnectError((error) {
        _isConnecting = false;
        if (kDebugMode) {
          debugPrint('LocationSocketService: Connection error: $error');
        }
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        if (kDebugMode) {
          debugPrint('LocationSocketService: Disconnected: $reason');
        }
      });

      _socket!.onError((error) {
        if (kDebugMode) {
          debugPrint('LocationSocketService: Error: $error');
        }
      });

      _socket!.on('connected', (data) {
        if (kDebugMode) {
          debugPrint(
            'LocationSocketService: Server confirmed connection: $data',
          );
        }
      });

      _socket!.on('location:received', (data) {
        if (kDebugMode) {
          debugPrint('LocationSocketService: Location update confirmed: $data');
        }
      });

      _socket!.on('error', (data) {
        if (kDebugMode) {
          debugPrint('LocationSocketService: Server error: $data');
        }
      });

      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      if (kDebugMode) {
        debugPrint('LocationSocketService: Failed to connect: $e');
      }
      rethrow;
    }
  }

  /// Send location update to the server
  void sendLocationUpdate({
    required int riderId,
    required double latitude,
    required double longitude,
    int? packageId,
    double? speed,
    double? heading,
  }) {
    if (!_isConnected || _socket == null) {
      if (kDebugMode) {
        debugPrint(
          'LocationSocketService: Not connected, attempting to connect...',
        );
      }
      connect(riderId: riderId).then((_) {
        // Retry after connection
        if (_isConnected) {
          _sendLocationUpdate(
            riderId: riderId,
            latitude: latitude,
            longitude: longitude,
            packageId: packageId,
            speed: speed,
            heading: heading,
          );
        }
      });
      return;
    }

    _sendLocationUpdate(
      riderId: riderId,
      latitude: latitude,
      longitude: longitude,
      packageId: packageId,
      speed: speed,
      heading: heading,
    );
  }

  void _sendLocationUpdate({
    required int riderId,
    required double latitude,
    required double longitude,
    int? packageId,
    double? speed,
    double? heading,
  }) {
    try {
      final data = {
        'rider_id': riderId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        if (packageId != null) 'package_id': packageId,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      };

      _socket!.emit('location:update', data);

      if (kDebugMode) {
        debugPrint(
          'LocationSocketService: Sent location update: rider_id=$riderId, lat=$latitude, lng=$longitude, package_id=$packageId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationSocketService: Error sending location: $e');
      }
    }
  }

  /// Disconnect from the server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _riderId = null;
  }
}
