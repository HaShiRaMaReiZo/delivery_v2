import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/api/api_endpoints.dart';

class LocationWebSocketService {
  IO.Socket? _socket;
  StreamController<Map<String, dynamic>>? _locationController;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isDisposed = false;

  final int packageId;
  final int userId;
  final String userRole;
  final int? merchantId;
  final String baseUrl;

  LocationWebSocketService({
    required this.packageId,
    required this.userId,
    required this.userRole,
    this.merchantId,
    // Get from ApiEndpoints
    this.baseUrl = ApiEndpoints.websocketBaseUrl,
  }) {
    _locationController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<Map<String, dynamic>> get locationStream =>
      _locationController!.stream;

  bool get isConnected => _socket != null && _socket!.connected;

  Future<void> connect() async {
    if (_isConnecting ||
        (_socket != null && _socket!.connected) ||
        _isDisposed) {
      return;
    }

    _isConnecting = true;
    try {
      debugPrint('Socket.io: Connecting to $baseUrl');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(999999) // Infinite reconnection attempts
            .build(),
      );

      // Connection event
      _socket!.onConnect((_) {
        debugPrint('Socket.io: Connection established');
        _isConnecting = false;

        // Join merchant room
        if (merchantId != null) {
          _socket!.emit('join:merchant', {
            'merchant_id': merchantId,
            'package_id': packageId,
          });
          debugPrint(
            'Socket.io: Joined merchant room: merchant.package.$packageId.location',
          );
        }
      });

      // Connection confirmation
      _socket!.on('connected', (data) {
        debugPrint('Socket.io: Connection confirmed: $data');
      });

      // Receive location updates
      _socket!.on('location:update', (data) {
        debugPrint('Socket.io: ⚡ Location update received: $data');
        try {
          final locationData = data as Map<String, dynamic>;
          _locationController?.add(locationData);
        } catch (e) {
          debugPrint('Socket.io: Error parsing location update: $e');
        }
      });

      // Error handling
      _socket!.onError((error) {
        debugPrint('Socket.io: ⚠️ Error: $error');
        _isConnecting = false;
        if (!_isDisposed) {
          _reconnect();
        }
      });

      // Disconnect handling
      _socket!.onDisconnect((_) {
        debugPrint('Socket.io: ⚠️ Disconnected');
        _isConnecting = false;
        if (!_isDisposed) {
          _reconnect();
        }
      });

      // Connect
      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      debugPrint('Socket.io: Failed to connect: $e');
      _socket = null;
      if (!_isDisposed) {
        _reconnect();
      }
    }
  }

  void _reconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _locationController?.close();
  }
}
