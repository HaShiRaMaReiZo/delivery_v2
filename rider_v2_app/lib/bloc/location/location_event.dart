import 'package:flutter/foundation.dart';

@immutable
sealed class LocationEvent {
  const LocationEvent();
}

class LocationStartEvent extends LocationEvent {
  final int? packageId;

  const LocationStartEvent({this.packageId});
}

class LocationStopEvent extends LocationEvent {
  const LocationStopEvent();
}

class LocationErrorEvent extends LocationEvent {
  final String error;

  const LocationErrorEvent(this.error);
}

class LocationUpdatePackageIdEvent extends LocationEvent {
  final int? packageId;

  const LocationUpdatePackageIdEvent(this.packageId);
}
