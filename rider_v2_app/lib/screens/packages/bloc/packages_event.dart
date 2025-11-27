import 'package:flutter/foundation.dart';

@immutable
sealed class PackagesEvent {
  const PackagesEvent();
}

class PackagesFetchRequested extends PackagesEvent {
  const PackagesFetchRequested();
}
