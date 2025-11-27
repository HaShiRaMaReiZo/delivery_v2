import 'package:flutter/foundation.dart';

@immutable
sealed class LocationState {
  const LocationState();
}

class LocationIdleState extends LocationState {
  const LocationIdleState();
}

class LocationActiveState extends LocationState {
  const LocationActiveState();
}

class LocationErrorState extends LocationState {
  final String message;

  const LocationErrorState(this.message);
}
