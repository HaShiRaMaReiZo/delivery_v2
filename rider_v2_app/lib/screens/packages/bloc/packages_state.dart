import 'package:flutter/foundation.dart';
import '../../../models/package_model.dart';
import '../../../models/merchant_model.dart';

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
  // Group pickups by merchant
  final Map<MerchantModel, List<PackageModel>> pickupsByMerchant;
  final int? actionPackageId; // Package ID being acted upon
  final bool isActionLoading; // Whether an action is in progress

  const PackagesLoaded({
    required this.assignedDeliveries,
    required this.pickups,
    required this.pickupsByMerchant,
    this.actionPackageId,
    this.isActionLoading = false,
  });

  PackagesLoaded copyWith({
    List<PackageModel>? assignedDeliveries,
    List<PackageModel>? pickups,
    Map<MerchantModel, List<PackageModel>>? pickupsByMerchant,
    int? actionPackageId,
    bool? isActionLoading,
  }) {
    return PackagesLoaded(
      assignedDeliveries: assignedDeliveries ?? this.assignedDeliveries,
      pickups: pickups ?? this.pickups,
      pickupsByMerchant: pickupsByMerchant ?? this.pickupsByMerchant,
      actionPackageId: actionPackageId ?? this.actionPackageId,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

class PackagesError extends PackagesState {
  final String message;

  const PackagesError(this.message);
}
