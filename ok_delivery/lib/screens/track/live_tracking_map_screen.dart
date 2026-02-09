import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/package_model.dart';
import '../../repositories/package_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../services/location_websocket_service.dart';
import 'widgets/package_details_sheet.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  final PackageModel package;

  const LiveTrackingMapScreen({super.key, required this.package});

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  final _packageRepository = PackageRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );
  final _authRepository = AuthRepository(
    ApiClient.create(baseUrl: ApiEndpoints.baseUrl),
  );

  final MapController _mapController = MapController();
  LocationWebSocketService? _wsService;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  Timer? _statusCheckTimer;
  bool _isLoading = true;
  String? _error;
  bool _isLive = false;
  bool _isDelivered = false;
  String? _currentStatus; // Track current package status

  // Rider location
  double? _riderLatitude;
  double? _riderLongitude;
  String? _riderName;
  int? _assignedRiderId; // Store the assigned rider_id to filter updates
  // ignore: unused_field
  DateTime? _lastUpdate;
  bool _mapReady = false;

  // Smooth animation for marker movement
  LatLng? _targetPosition; // Target position from WebSocket
  LatLng? _currentMapPosition; // Current animated position
  LatLng?
  _animationStartPosition; // Position when animation to current target started
  DateTime? _targetPositionTimestamp; // When target position was set
  Timer? _mapUpdateTimer; // Timer for smooth animation
  static const Duration _expectedUpdateInterval = Duration(
    seconds: 3,
  ); // Expected GPS update interval

  bool _isInTransit(String? status) {
    return status == 'on_the_way';
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.package.status;

    // If already in transit, connect WebSocket immediately after first frame
    if (_isInTransit(_currentStatus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _connectWebSocket();
        }
      });
    }

    _loadLocation();

    // Periodically check if status changed to on_the_way
    // This handles cases where status changes after screen opens
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isInTransit(_currentStatus)) {
        _loadLocation(); // Re-check status
      } else {
        timer.cancel(); // Stop checking once we're in transit
      }
    });
  }

  Future<void> _connectWebSocket() async {
    // Prevent duplicate connections
    if (_wsService != null && _wsService!.isConnected) {
      debugPrint('WebSocket already connected, skipping...');
      return;
    }

    // Prevent multiple simultaneous connection attempts
    if (_wsService != null && !_wsService!.isConnected) {
      debugPrint(
        'WebSocket connection in progress, skipping duplicate call...',
      );
      return;
    }

    // Get user data from repository instead of AuthBloc
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        debugPrint('User not found, skipping WebSocket connection');
        return;
      }

      final merchantId = user.merchant?.id;
      if (merchantId == null) {
        debugPrint('Merchant ID not found, skipping WebSocket connection');
        return;
      }

      // Dispose existing service if any (but only if not connected)
      if (_wsService != null && !_wsService!.isConnected) {
        debugPrint('Disposing existing disconnected WebSocket service...');
        _wsService!.disconnect();
        _wsSubscription?.cancel();
        _wsService = null;
        _wsSubscription = null;
      }

      _wsService = LocationWebSocketService(
        packageId: widget.package.id,
        userId: user.id,
        userRole: user.role,
        merchantId: merchantId,
      );

      _wsSubscription = _wsService!.locationStream.listen(
        (data) {
          debugPrint('LiveTrackingMapScreen: Received location update: $data');
          if (mounted) {
            // Filter by rider_id - only accept updates from the assigned rider
            final updateRiderId = (data['rider_id'] as num?)?.toInt();
            if (_assignedRiderId != null) {
              if (updateRiderId == null || updateRiderId != _assignedRiderId) {
                debugPrint(
                  'LiveTrackingMapScreen: Ignoring location update from rider_id=$updateRiderId (assigned rider_id=$_assignedRiderId)',
                );
                return; // Ignore updates from other riders or missing rider_id
              }
            } else if (updateRiderId != null) {
              // If we don't have an assigned rider_id yet, set it from the first update
              // This handles edge cases where rider assignment happens after WebSocket connection
              debugPrint(
                'LiveTrackingMapScreen: Setting assigned rider_id from update: $updateRiderId',
              );
              _assignedRiderId = updateRiderId;
            }

            final newLat = (data['latitude'] as num?)?.toDouble();
            final newLng = (data['longitude'] as num?)?.toDouble();

            if (newLat != null && newLng != null) {
              debugPrint(
                'LiveTrackingMapScreen: Updating location to lat: $newLat, lng: $newLng',
              );

              // Set target position for smooth animation
              _targetPosition = LatLng(newLat, newLng);

              // IMPORTANT: When new location arrives, reset animation from CURRENT visual position
              // Use the current displayed position (where marker is visually now) as start point
              _animationStartPosition = _currentMapPosition ?? _targetPosition;

              // Reset timestamp to restart animation timer
              _targetPositionTimestamp = DateTime.now();

              if (_currentMapPosition == null) {
                _currentMapPosition = _targetPosition;
                _animationStartPosition = _targetPosition;
              }

              setState(() {
                // Update actual rider location (for display)
                _riderLatitude = newLat;
                _riderLongitude = newLng;
                // Note: Go server sends rider_id, not rider_name
                // We'll keep the name from initial load or fetch separately if needed
                if (data['last_update'] != null) {
                  try {
                    _lastUpdate = DateTime.parse(data['last_update']);
                  } catch (e) {
                    debugPrint('Error parsing last_update: $e');
                    _lastUpdate = DateTime.now();
                  }
                } else {
                  _lastUpdate = DateTime.now();
                }
                _isLive = true;
              });

              // Start smooth animation if map is ready
              // Timer will automatically use the updated _targetPosition and _targetPositionTimestamp
              if (_mapReady && _targetPosition != null) {
                _startSmoothAnimation();
              }
            } else {
              debugPrint(
                'LiveTrackingMapScreen: Invalid location data - lat: $newLat, lng: $newLng',
              );
            }
          }
        },
        onError: (error) {
          debugPrint('LiveTrackingMapScreen: WebSocket stream error: $error');
        },
        cancelOnError: false,
      );

      debugPrint('LiveTrackingMapScreen: Starting WebSocket connection...');
      _wsService!.connect();
    } catch (e) {
      debugPrint('Error connecting WebSocket: $e');
    }
  }

  void _startSmoothAnimation() {
    // Don't start if we don't have required data
    if (_targetPosition == null || !_mapReady || !mounted) {
      return;
    }

    // Initialize current position if not set
    if (_currentMapPosition == null) {
      if (_riderLatitude != null && _riderLongitude != null) {
        _currentMapPosition = LatLng(_riderLatitude!, _riderLongitude!);
      } else {
        _currentMapPosition = _targetPosition;
      }
    }

    // Initialize animation start position if not set
    if (_animationStartPosition == null) {
      _animationStartPosition = _currentMapPosition;
    }

    // Initialize timestamp if not set
    if (_targetPositionTimestamp == null) {
      _targetPositionTimestamp = DateTime.now();
    }

    // Only start timer if it's not already running
    // When timer is already running, it will automatically pick up the new target position
    // (New target position is set before calling this function)
    if (_mapUpdateTimer != null && _mapUpdateTimer!.isActive) {
      // Timer already running - it will use the updated _targetPosition and _targetPositionTimestamp
      return;
    }

    // Smooth map animation timer (updates 30 times per second for smooth movement)
    // Uses time-based interpolation to animate over the full 5-second interval
    _mapUpdateTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_targetPosition == null ||
          _currentMapPosition == null ||
          _targetPositionTimestamp == null ||
          !mounted ||
          !_mapReady) {
        timer.cancel();
        return;
      }

      if (_animationStartPosition == null) {
        _animationStartPosition = _currentMapPosition ?? _targetPosition;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_targetPositionTimestamp!);

      // Calculate progress (0.0 to 1.0) over the expected interval
      final progress =
          (elapsed.inMilliseconds / _expectedUpdateInterval.inMilliseconds)
              .clamp(0.0, 1.0);

      if (progress >= 1.0) {
        // Animation complete - STOP at target position (no prediction/extrapolation)
        // This prevents overshooting beyond the actual GPS position
        _currentMapPosition = _targetPosition;

        // Don't cancel timer - keep it running in case new update arrives
        // Timer will automatically pick up new _targetPosition when it's set
      } else {
        // Still animating - interpolate from start to target based on time progress
        // Use smooth easing (ease-out cubic) for natural movement
        final easedProgress =
            1 - (1 - progress) * (1 - progress) * (1 - progress);

        // Calculate total distance from start to target
        final totalLatDiff =
            _targetPosition!.latitude - _animationStartPosition!.latitude;
        final totalLngDiff =
            _targetPosition!.longitude - _animationStartPosition!.longitude;

        // Interpolate position from start to target
        _currentMapPosition = LatLng(
          _animationStartPosition!.latitude + (totalLatDiff * easedProgress),
          _animationStartPosition!.longitude + (totalLngDiff * easedProgress),
        );
      }

      // Update marker position smoothly
      setState(() {
        _riderLatitude = _currentMapPosition!.latitude;
        _riderLongitude = _currentMapPosition!.longitude;
      });

      // Note: Map does NOT auto-center on rider updates
      // User can use the center button to manually center on rider
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _mapUpdateTimer?.cancel();
    _wsSubscription?.cancel();
    _wsService?.disconnect();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final response = await _packageRepository.getLiveLocation(
        widget.package.id,
      );

      if (mounted) {
        _currentStatus = response.package.status;

        setState(() {
          _isLoading = false;
          _isLive = response.isLive;
          // Check status from response, not just initial package status
          _isDelivered = response.package.status == 'delivered';

          if (response.rider != null) {
            _riderLatitude = response.rider!.latitude;
            _riderLongitude = response.rider!.longitude;
            _riderName = response.rider!.name;
            _assignedRiderId = response.rider!.id; // Store assigned rider_id
            _lastUpdate = response.rider!.lastUpdate;

            // Center map on rider location (only if map is ready)
            if (_riderLatitude != null &&
                _riderLongitude != null &&
                _mapReady) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final initialPosition = LatLng(
                    _riderLatitude!,
                    _riderLongitude!,
                  );
                  _currentMapPosition = initialPosition;
                  _targetPosition = initialPosition;
                  _mapController.move(initialPosition, 15.0);
                } catch (e) {
                  debugPrint('Error moving map: $e');
                }
              });
            }
          } else {
            _error = response.message ?? 'No location data available';
          }
        });

        // Connect WebSocket if status changed to on_the_way
        // This handles cases where status changes to on_the_way after screen opens
        if (_isInTransit(response.package.status)) {
          if (_wsService == null) {
            debugPrint('Status is on_the_way, connecting WebSocket...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _connectWebSocket();
                // Stop status checking timer since we're now in transit
                _statusCheckTimer?.cancel();
              }
            });
          } else if (!_wsService!.isConnected) {
            debugPrint(
              'WebSocket service exists but not connected, reconnecting...',
            );
            _wsService!.connect();
          }
        } else {
          // If status is not on_the_way, disconnect WebSocket
          if (_wsService != null) {
            debugPrint('Status is not on_the_way, disconnecting WebSocket...');
            _wsService!.disconnect();
            _wsService = null;
            _wsSubscription?.cancel();
            _wsSubscription = null;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.neutral50,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.neutral900,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        leadingWidth: 64,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live tracking',
              style: TextStyle(
                color: AppTheme.neutral900,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.package.trackingCode ?? 'No tracking code',
              style: const TextStyle(color: AppTheme.neutral500, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadLocation();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _riderLatitude == null || _riderLongitude == null
          ? const Center(
              child: Text(
                'No location data available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_riderLatitude!, _riderLongitude!),
                    initialZoom: 15.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    onMapReady: () {
                      setState(() {
                        _mapReady = true;
                      });
                      // Start smooth animation if we already have target position
                      if (_targetPosition != null) {
                        _startSmoothAnimation();
                      }
                      // Center map on rider location after map is ready
                      if (_riderLatitude != null && _riderLongitude != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          try {
                            _mapController.move(
                              LatLng(_riderLatitude!, _riderLongitude!),
                              15.0,
                            );
                          } catch (e) {
                            debugPrint('Error centering map: $e');
                          }
                        });
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.okdelivery.app',
                      maxZoom: 19,
                    ),
                    // Markers
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_riderLatitude!, _riderLongitude!),
                          width: 40,
                          height: 40,
                          key: ValueKey(
                            'rider_${_riderLatitude}_${_riderLongitude}',
                          ), // Force rebuild on location change
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing animation for live tracking
                              if (_isLive && !_isDelivered)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.2),
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.easeInOut,
                                  builder: (context, value, child) {
                                    return Container(
                                      width: 40 * value,
                                      height: 40 * value,
                                      decoration: BoxDecoration(
                                        color: AppTheme.yellow400.withValues(
                                          alpha: 0.18,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                              // Main marker
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.neutral900,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isDelivered
                                      ? Icons.flag_rounded
                                      : Icons.delivery_dining,
                                  color: AppTheme.yellow400,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Center map on rider button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      // Center map on rider location
                      if (_riderLatitude != null && _riderLongitude != null) {
                        _mapController.move(
                          LatLng(_riderLatitude!, _riderLongitude!),
                          _mapController.camera.zoom,
                        );
                      }
                    },
                    backgroundColor: AppTheme.darkBlue,
                    child: const Icon(Icons.my_location, color: Colors.white),
                    tooltip: 'Center on rider',
                  ),
                ),
                // Draggable package details bottom sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.28,
                  minChildSize: 0.20,
                  maxChildSize: 0.65,
                  snap: true,
                  snapSizes: const [0.28, 0.5, 0.65],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(color: AppTheme.neutral100, width: 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: PackageDetailsSheet(
                          packageDetails: PackageDetails(
                            trackingNumber:
                                widget.package.trackingCode ??
                                'No tracking code',
                            customer: widget.package.customerName,
                            phone: widget.package.customerPhone,
                            destination: widget.package.deliveryAddress,
                            driverName: _riderName ?? 'Driver',
                            driverPhone: '',
                            estimatedTime: '',
                            distance:
                                _riderLatitude != null &&
                                    _riderLongitude != null
                                ? '${_riderLatitude!.toStringAsFixed(5)}, '
                                      '${_riderLongitude!.toStringAsFixed(5)}'
                                : 'Unknown',
                            currentLocation:
                                _riderLatitude != null &&
                                    _riderLongitude != null
                                ? '${_riderLatitude!.toStringAsFixed(5)}, '
                                      '${_riderLongitude!.toStringAsFixed(5)}'
                                : 'Unknown',
                          ),
                          onCallDriver: () {
                            _showSnack('Driver phone not available');
                          },
                          onContactCustomer: () {
                            final phone = widget.package.customerPhone;
                            if (phone.isNotEmpty) {
                              _makePhoneCall(phone);
                            } else {
                              _showSnack('Customer phone not available');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Placeholder: integrate url_launcher when available
    _showSnack('Dialer not available on this build');
  }
}
