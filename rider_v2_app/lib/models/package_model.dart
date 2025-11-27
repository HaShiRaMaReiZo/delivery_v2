import 'package:json_annotation/json_annotation.dart';
import 'merchant_model.dart';
import 'package_status_history_model.dart';

part 'package_model.g.dart';

@JsonSerializable()
class PackageModel {
  final int id;
  @JsonKey(name: 'tracking_code')
  final String? trackingCode;
  @JsonKey(name: 'merchant_id')
  final int merchantId;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'customer_phone')
  final String customerPhone;
  @JsonKey(name: 'delivery_address')
  final String deliveryAddress;
  @JsonKey(name: 'delivery_latitude', fromJson: _coordinateFromJson)
  final double? deliveryLatitude;
  @JsonKey(name: 'delivery_longitude', fromJson: _coordinateFromJson)
  final double? deliveryLongitude;
  @JsonKey(name: 'payment_type')
  final String paymentType;
  @JsonKey(name: 'amount', fromJson: _amountFromJson)
  final double amount;
  @JsonKey(name: 'package_image')
  final String? packageImage;
  @JsonKey(name: 'package_description')
  final String? packageDescription;
  final String? status;
  @JsonKey(name: 'current_rider_id')
  final int? currentRiderId;
  @JsonKey(name: 'assigned_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? assignedAt;
  @JsonKey(name: 'picked_up_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? pickedUpAt;
  @JsonKey(name: 'delivered_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? deliveredAt;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;
  final MerchantModel? merchant;
  @JsonKey(name: 'status_history')
  final List<PackageStatusHistoryModel>? statusHistory;

  static DateTime _dateTimeFromJson(String dateString) {
    return DateTime.parse(dateString).toUtc();
  }

  static DateTime? _dateTimeFromJsonNullable(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    return DateTime.parse(dateString).toUtc();
  }

  static double? _coordinateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static double _amountFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  PackageModel({
    required this.id,
    this.trackingCode,
    required this.merchantId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.paymentType,
    required this.amount,
    this.packageImage,
    this.packageDescription,
    this.status,
    this.currentRiderId,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.merchant,
    this.statusHistory,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) =>
      _$PackageModelFromJson(json);
  Map<String, dynamic> toJson() => _$PackageModelToJson(this);

  /// Check if this package is for delivery
  /// Delivery packages include:
  /// - ready_for_delivery: Received from office, ready to start delivery
  /// - on_the_way: Currently being delivered
  /// - assigned_to_rider: If previous status was arrived_at_office (delivery assignment)
  /// - cancelled: Cancelled packages need to be returned to office
  bool get isForDelivery {
    if (status == 'ready_for_delivery' ||
        status == 'on_the_way' ||
        status == 'cancelled') {
      return true;
    }

    // For assigned_to_rider, check status history to distinguish pickup vs delivery
    if (status == 'assigned_to_rider') {
      return _isDeliveryAssignment();
    }

    return false;
  }

  /// Check if this package is for pickup
  /// Pickup packages include:
  /// - assigned_to_rider: If previous status was NOT arrived_at_office (pickup from merchant)
  /// - picked_up: Picked up from merchant
  bool get isForPickup {
    if (status == 'picked_up') {
      return true;
    }

    // For assigned_to_rider, check status history to distinguish pickup vs delivery
    if (status == 'assigned_to_rider') {
      return !_isDeliveryAssignment();
    }

    return false;
  }

  /// Check if assigned_to_rider status is for delivery (not pickup)
  /// Returns true if previous status in history was arrived_at_office
  bool _isDeliveryAssignment() {
    if (statusHistory == null || statusHistory!.isEmpty) {
      // If no history, default to pickup (safer assumption)
      return false;
    }

    // Sort status history by created_at descending
    final sortedHistory = List<PackageStatusHistoryModel>.from(statusHistory!)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Check the second entry (skip current assigned_to_rider status)
    if (sortedHistory.length > 1) {
      final previousStatus = sortedHistory[1].status;
      return previousStatus == 'arrived_at_office';
    }

    // If only one entry (current status), default to pickup
    return false;
  }
}
