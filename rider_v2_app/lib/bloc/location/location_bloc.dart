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
  }

  final LocationService service;
  Timer? _timer;
  StreamSubscription<Position>? _streamSubscription;
  StreamSubscription<location_package.LocationData>?
  _backgroundStreamSubscription;
  location_package.Location? _backgroundLocation;
  int? _currentPackageId;

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
        accuracy: location_package.LocationAccuracy.high,
        interval: 5000, // Update every 5 seconds
        distanceFilter: 10, // Or every 10 meters (whichever comes first)
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
    _backgroundStreamSubscription = _backgroundLocation?.onLocationChanged
        .listen(
          (location_package.LocationData locationData) {
            if (locationData.latitude != null &&
                locationData.longitude != null) {
              // Send location update to server
              service
                  .update(
                    latitude: locationData.latitude!,
                    longitude: locationData.longitude!,
                    packageId: _currentPackageId,
                    speed: locationData.speed,
                    heading: locationData.heading,
                  )
                  .catchError((error) {
                    // Log error and emit error event
                    if (kDebugMode) {
                      debugPrint('Location update failed (background): $error');
                    }
                    add(LocationErrorEvent(error.toString()));
                  });
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
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
            timeLimit: Duration(seconds: 5), // Or every 5 seconds
          ),
        ).listen(
          (Position position) {
            // Send location update to server
            if (kDebugMode) {
              debugPrint(
                'LocationBloc: Foreground stream received position: ${position.latitude}, ${position.longitude}',
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
                      'LocationBloc: Foreground location update sent successfully',
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Don't wait too long
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
