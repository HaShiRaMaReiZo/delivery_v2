import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_package;
import 'package:permission_handler/permission_handler.dart';
import '../../services/location_service.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc({required this.service}) : super(const LocationIdleState()) {
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('LocationBloc: Constructor called');
      debugPrint('LocationBloc: Service provided: ${service.runtimeType}');
      debugPrint('========================================');
    }
    on<LocationStartEvent>(_onStart);
    on<LocationStopEvent>(_onStop);
    on<LocationErrorEvent>(_onError);
    on<LocationUpdatePackageIdEvent>(_onUpdatePackageId);
  }

  final LocationService service;
  Timer? _timer;
  StreamSubscription<Position>? _streamSubscription;
  StreamSubscription<location_package.LocationData>?
  _backgroundStreamSubscription;
  location_package.Location? _backgroundLocation;
  int? _currentPackageId;
  Position? _lastGoodPosition; // Track last known good GPS position
  int _poorAccuracyCount = 0; // Count consecutive poor accuracy readings

  Future<void> _onStart(
    LocationStartEvent event,
    Emitter<LocationState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('LocationBloc: _onStart called');
      debugPrint(
        'LocationBloc: Start event received, packageId: ${event.packageId}',
      );
      debugPrint('LocationBloc: Current state: ${state.runtimeType}');
      debugPrint('========================================');
    }

    _timer?.cancel();
    _streamSubscription?.cancel();
    _backgroundStreamSubscription?.cancel();

    // Request location permissions
    if (kDebugMode) {
      debugPrint('LocationBloc: Checking if location service is enabled...');
    }
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (kDebugMode) {
      debugPrint('LocationBloc: Location service enabled: $serviceEnabled');
    }
    if (!serviceEnabled) {
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Location service is disabled, attempting to open settings...',
        );
      }
      // Try to open location settings so user can enable it
      try {
        await Geolocator.openLocationSettings();
        if (kDebugMode) {
          debugPrint('LocationBloc: Location settings opened');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LocationBloc: Failed to open location settings: $e');
        }
      }
      emit(
        const LocationErrorState(
          'Location services are disabled. Please enable location/GPS in your device settings.',
        ),
      );
      return;
    }

    // Check and request foreground location permission
    if (kDebugMode) {
      debugPrint('LocationBloc: Checking foreground location permission...');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (kDebugMode) {
      debugPrint('LocationBloc: Current permission status: $permission');
    }

    if (permission == LocationPermission.denied) {
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('LocationBloc: Permission denied, requesting...');
        debugPrint('LocationBloc: This should show permission dialog');
        debugPrint('========================================');
      }
      permission = await Geolocator.requestPermission();
      if (kDebugMode) {
        debugPrint('LocationBloc: Permission after request: $permission');
        debugPrint('LocationBloc: Permission dialog should have appeared');
      }

      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          debugPrint('LocationBloc: Permission still denied, emitting error');
        }
        emit(const LocationErrorState('Location permissions are denied.'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Permission permanently denied, emitting error',
        );
      }
      emit(
        const LocationErrorState(
          'Location permissions are permanently denied. Please enable in settings.',
        ),
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('LocationBloc: Foreground permission granted, continuing...');
    }

    // Request background location permission (Android 10+)
    // This is OPTIONAL for foreground tracking, but REQUIRED for background tracking
    if (kDebugMode) {
      debugPrint('LocationBloc: Checking background location permission...');
    }
    try {
      PermissionStatus backgroundPermission =
          await Permission.locationAlways.status;
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Background permission status: $backgroundPermission',
        );
      }

      if (backgroundPermission.isDenied) {
        if (kDebugMode) {
          debugPrint(
            'LocationBloc: Background permission denied, requesting (non-blocking)...',
          );
        }
        // Request but don't wait - start tracking immediately
        Permission.locationAlways.request().then((status) {
          if (kDebugMode) {
            debugPrint(
              'LocationBloc: Background permission request result: $status',
            );
          }
        });
      }

      // Don't block tracking if background permission is denied
      // Foreground tracking will still work
      if (backgroundPermission.isPermanentlyDenied) {
        if (kDebugMode) {
          debugPrint(
            'WARNING: Background location permission permanently denied. Foreground tracking will still work.',
          );
        }
      } else if (backgroundPermission.isDenied) {
        if (kDebugMode) {
          debugPrint(
            'WARNING: Background location permission not granted. Location tracking may stop when app is closed.',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('LocationBloc: Background permission granted!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Error checking background permission: $e (continuing anyway)',
        );
      }
    }

    if (kDebugMode) {
      debugPrint(
        'LocationBloc: Emitting active state, starting location tracking...',
      );
    }
    emit(const LocationActiveState());
    _currentPackageId = event.packageId;

    if (kDebugMode) {
      debugPrint('LocationBloc: Initializing background location service...');
    }
    // Initialize background location service
    _backgroundLocation ??= location_package.Location();

    if (kDebugMode) {
      debugPrint('LocationBloc: Configuring background location settings...');
    }
    // Configure background location settings for better battery efficiency
    try {
      await _backgroundLocation?.changeSettings(
        accuracy: location_package.LocationAccuracy.high, // Use high accuracy
        interval: 3000, // Update every 3 seconds
        distanceFilter: 5, // Or every 5 meters (whichever comes first)
      );
      if (kDebugMode) {
        debugPrint('LocationBloc: Background location settings configured');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationBloc: Error configuring background settings: $e');
      }
    }

    // Enable background mode for continuous tracking
    if (kDebugMode) {
      debugPrint('LocationBloc: Enabling background mode...');
    }
    try {
      await _backgroundLocation?.enableBackgroundMode(enable: true);
      if (kDebugMode) {
        debugPrint('LocationBloc: Background mode enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationBloc: Error enabling background mode: $e');
      }
    }

    // Start background location tracking
    if (kDebugMode) {
      debugPrint('LocationBloc: Starting background location stream...');
    }
    _backgroundStreamSubscription = _backgroundLocation?.onLocationChanged.listen(
      (location_package.LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          // Send location update to server
          if (kDebugMode) {
            debugPrint(
              'LocationBloc: 📍 BACKGROUND location update: lat=${locationData.latitude}, lng=${locationData.longitude}, packageId: $_currentPackageId',
            );
            debugPrint(
              'LocationBloc: Sending background location update to server...',
            );
          }
          service
              .update(
                latitude: locationData.latitude!,
                longitude: locationData.longitude!,
                packageId: _currentPackageId,
                speed: locationData.speed,
                heading: locationData.heading,
              )
              .then((_) {
                if (kDebugMode) {
                  debugPrint(
                    'LocationBloc: ✅ Background location update sent successfully',
                  );
                }
              })
              .catchError((error) {
                // Log error and emit error event
                if (kDebugMode) {
                  debugPrint(
                    'LocationBloc: ❌ Location update failed (background): $error',
                  );
                }
                add(LocationErrorEvent(error.toString()));
              });
        } else {
          if (kDebugMode) {
            debugPrint(
              'LocationBloc: ⚠️ Background location data missing lat/lng: $locationData',
            );
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('Background location stream error: $error');
        }
        add(LocationErrorEvent(error.toString()));
      },
      cancelOnError: false, // Continue tracking even if errors occur
    );

    // Also start foreground tracking for immediate updates
    if (kDebugMode) {
      debugPrint('LocationBloc: Starting foreground location stream...');
    }
    _streamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, // Use best GPS accuracy
            distanceFilter: 5, // Update every 5 meters
            timeLimit: Duration(seconds: 3), // Or every 3 seconds
          ),
        ).listen(
          (Position position) {
            // Check GPS quality and warn user if accuracy is poor
            _checkGpsQuality(position);

            // Send location update to server
            if (kDebugMode) {
              debugPrint(
                'LocationBloc: 📍 FOREGROUND location update: lat=${position.latitude}, lng=${position.longitude}, packageId: $_currentPackageId',
              );
              debugPrint(
                'LocationBloc: Accuracy: ${position.accuracy}m, Timestamp: ${position.timestamp}',
              );
              debugPrint(
                'LocationBloc: Sending foreground location update to server...',
              );
            }
            service
                .update(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  packageId: _currentPackageId,
                  speed: position.speed,
                  heading: position.heading,
                )
                .then((_) {
                  if (kDebugMode) {
                    debugPrint(
                      'LocationBloc: ✅ Foreground location update sent successfully',
                    );
                  }
                })
                .catchError((error) {
                  // Log error and emit error event
                  if (kDebugMode) {
                    debugPrint('Location update failed (foreground): $error');
                  }
                  add(LocationErrorEvent(error.toString()));
                });
          },
          onError: (error) {
            add(LocationErrorEvent(error.toString()));
          },
        );

    // Also send initial location immediately
    // This is critical - ensures rider appears on map right after login
    try {
      if (kDebugMode) {
        debugPrint('Fetching initial location...');
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // Use best GPS accuracy
        timeLimit: const Duration(seconds: 15), // Wait longer for GPS fix
      );
      if (kDebugMode) {
        debugPrint(
          'Got initial position: ${position.latitude}, ${position.longitude}',
        );
      }

      await service.update(
        latitude: position.latitude,
        longitude: position.longitude,
        packageId: event.packageId,
        speed: position.speed,
        heading: position.heading,
      );

      if (kDebugMode) {
        debugPrint(
          'Initial location sent successfully: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      // Initial location fetch failed, but stream will continue
      if (kDebugMode) {
        debugPrint('Initial location fetch failed: $e');
        debugPrint(
          'Location streams will continue, but initial location was not sent.',
        );
      }
      // Don't emit error state - let streams handle it
      // The foreground and background streams will send location once they get a fix
    }
  }

  Future<void> _onStop(
    LocationStopEvent event,
    Emitter<LocationState> emit,
  ) async {
    _timer?.cancel();
    _streamSubscription?.cancel();
    _backgroundStreamSubscription?.cancel();

    // Disable background mode
    if (_backgroundLocation != null) {
      await _backgroundLocation?.enableBackgroundMode(enable: false);
    }

    _currentPackageId = null;
    emit(const LocationIdleState());
  }

  void _onError(LocationErrorEvent event, Emitter<LocationState> emit) {
    // Log error but don't stop tracking
    // Only emit error state if we're not already tracking
    // This prevents error messages from flashing while tracking is active
    if (state is LocationIdleState) {
      emit(LocationErrorState(event.error));
    }
    // If already tracking, silently continue (errors are logged in service)
  }

  void _onUpdatePackageId(
    LocationUpdatePackageIdEvent event,
    Emitter<LocationState> emit,
  ) {
    if (kDebugMode) {
      debugPrint(
        'LocationBloc: ⚡ Updating package ID from $_currentPackageId to ${event.packageId}',
      );
      debugPrint(
        'LocationBloc: Next location update will include packageId: ${event.packageId}',
      );
    }
    _currentPackageId = event.packageId;

    // If location tracking is active, send an immediate update with the new package ID
    // This ensures the merchant app receives location updates as soon as package ID is set
    if (state is LocationActiveState) {
      _sendImmediateLocationUpdate();
    }
  }

  /// Send an immediate location update with current package ID
  Future<void> _sendImmediateLocationUpdate() async {
    try {
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Sending immediate location update with packageId: $_currentPackageId',
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // Use best GPS accuracy
        timeLimit: const Duration(seconds: 10), // Wait longer for GPS fix
      );

      // Check GPS quality
      _checkGpsQuality(position);

      // Send update with current package ID
      await service.update(
        latitude: position.latitude,
        longitude: position.longitude,
        packageId: _currentPackageId,
        speed: position.speed,
        heading: position.heading,
      );

      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Immediate location update sent successfully with packageId: $_currentPackageId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'LocationBloc: Failed to send immediate location update: $e',
        );
      }
      // Don't emit error - this is a non-critical update
    }
  }

  /// Check GPS quality and emit warnings if accuracy is poor
  void _checkGpsQuality(Position position) {
    // Check if accuracy is poor (likely using network location instead of GPS)
    if (position.accuracy > 100) {
      // Very poor accuracy - likely network location
      _poorAccuracyCount++;

      if (_poorAccuracyCount >= 3) {
        // After 3 consecutive poor readings, warn the user
        if (kDebugMode) {
          debugPrint(
            'LocationBloc: ⚠️ GPS accuracy is poor (${position.accuracy}m). This may be network location instead of GPS.',
          );
        }

        // Emit warning state (user-friendly message)
        add(
          LocationErrorEvent(
            'GPS accuracy is poor (${position.accuracy.toStringAsFixed(0)}m). '
            'Please ensure:\n'
            '• GPS is enabled in device settings\n'
            '• You are outdoors or have clear view of sky\n'
            '• Mock location is disabled in Developer Options',
          ),
        );

        // Try to open location settings to help user
        Geolocator.openLocationSettings().catchError((e) {
          if (kDebugMode) {
            debugPrint('LocationBloc: Could not open location settings: $e');
          }
          return false;
        });

        _poorAccuracyCount = 0; // Reset counter
      }
    } else if (position.accuracy <= 20) {
      // Good GPS accuracy - reset counter
      _poorAccuracyCount = 0;
      _lastGoodPosition = position;
    }

    // Check if location seems to have jumped significantly (possible mock location)
    if (_lastGoodPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastGoodPosition!.latitude,
        _lastGoodPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // If location jumped more than 1km in 3 seconds, likely mock location
      if (distance > 1000 &&
          position.timestamp
                  .difference(_lastGoodPosition!.timestamp)
                  .inSeconds <
              3) {
        if (kDebugMode) {
          debugPrint(
            'LocationBloc: ⚠️ Location jumped ${distance.toStringAsFixed(0)}m in ${position.timestamp.difference(_lastGoodPosition!.timestamp).inSeconds}s. Possible mock location.',
          );
        }

        add(
          LocationErrorEvent(
            'Location accuracy issue detected. '
            'Please disable "Mock location app" in Developer Options if enabled.',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    _backgroundStreamSubscription?.cancel();

    // Disable background mode
    _backgroundLocation?.enableBackgroundMode(enable: false);

    return super.close();
  }
}
