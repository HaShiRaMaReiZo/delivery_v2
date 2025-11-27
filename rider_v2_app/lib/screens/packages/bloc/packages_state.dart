import 'package:flutter/foundation.dart';
import '../../../models/package_model.dart';

@immutable
sealed class PackagesState {
  const PackagesState();
}

class PackagesInitial extends PackagesState {
  const PackagesInitial();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  final List<PackageModel> assignedDeliveries;
  final List<PackageModel> pickups;

  const PackagesLoaded({
    required this.assignedDeliveries,
    required this.pickups,
  });
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError(this.message);
}
