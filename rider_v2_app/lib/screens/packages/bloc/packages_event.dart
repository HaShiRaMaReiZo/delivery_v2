import 'package:flutter/foundation.dart';
import 'dart:io';

@immutable
sealed class PackagesEvent {
  const PackagesEvent();
}

class PackagesFetchRequested extends PackagesEvent {
  const PackagesFetchRequested();
}

class PackageConfirmPickupRequested extends PackagesEvent {
  final int merchantId;

  const PackageConfirmPickupRequested(this.merchantId);
}

class PackageReceiveFromOfficeRequested extends PackagesEvent {
  final int packageId;
  final String? notes;

  const PackageReceiveFromOfficeRequested(this.packageId, {this.notes});
}

class PackageStartDeliveryRequested extends PackagesEvent {
  final int packageId;

  const PackageStartDeliveryRequested(this.packageId);
}

class PackageMarkDeliveredRequested extends PackagesEvent {
  final int packageId;
  final File? photo;
  final String? signature;
  final double? latitude;
  final double? longitude;
  final String? deliveredToName;
  final String? deliveredToPhone;
  final String? notes;

  const PackageMarkDeliveredRequested(
    this.packageId, {
    this.photo,
    this.signature,
    this.latitude,
    this.longitude,
    this.deliveredToName,
    this.deliveredToPhone,
    this.notes,
  });
}

class PackageCollectCodRequested extends PackagesEvent {
  final int packageId;
  final double amount;
  final File? collectionProof;

  const PackageCollectCodRequested(
    this.packageId,
    this.amount, {
    this.collectionProof,
  });
}

class PackageContactCustomerRequested extends PackagesEvent {
  final int packageId;
  final String contactResult; // 'success' or 'failed'
  final String? notes;

  const PackageContactCustomerRequested(
    this.packageId,
    this.contactResult, {
    this.notes,
  });
}

class PackageReturnToOfficeRequested extends PackagesEvent {
  final int packageId;
  final String? notes;

  const PackageReturnToOfficeRequested(this.packageId, {this.notes});
}
