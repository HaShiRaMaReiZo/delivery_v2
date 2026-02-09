import 'package:json_annotation/json_annotation.dart';

part 'package_model.g.dart';

@JsonSerializable()
class PackageModel {
  final int id;
  @JsonKey(name: 'tracking_code')
  final String? trackingCode; // Nullable for drafts
  @JsonKey(name: 'merchant_id')
  final int merchantId;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'customer_phone')
  final String customerPhone;
  @JsonKey(name: 'delivery_address')
  final String deliveryAddress;
  @JsonKey(name: 'delivery_latitude')
  final double? deliveryLatitude;
  @JsonKey(name: 'delivery_longitude')
  final double? deliveryLongitude;
  @JsonKey(name: 'payment_type')
  final String paymentType; // 'cod' or 'prepaid'
  @JsonKey(fromJson: _amountFromJson)
  final double amount;
  @JsonKey(name: 'package_image')
  final String? packageImage;
  @JsonKey(name: 'package_description')
  final String? packageDescription;
  final String? status; // Nullable for drafts
  @JsonKey(name: 'registered_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? registeredAt; // Nullable - only set when package is registered
  @JsonKey(name: 'delivered_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? deliveredAt; // Nullable - only set when package is delivered
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;

  static DateTime _dateTimeFromJson(String dateString) {
    return DateTime.parse(dateString).toUtc();
  }

  static DateTime? _dateTimeFromJsonNullable(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    return DateTime.parse(dateString).toUtc();
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
    this.status, // Nullable for drafts
    this.registeredAt, // Nullable - only set when package is registered
    this.deliveredAt, // Nullable - only set when package is delivered
    required this.createdAt,
    required this.updatedAt,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) =>
      _$PackageModelFromJson(json);
  Map<String, dynamic> toJson() => _$PackageModelToJson(this);
}

// Model for creating a package (without id, timestamps, etc.)
class CreatePackageModel {
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String paymentType; // 'cod' or 'prepaid'
  final double amount;
  final String? packageImage; // Base64 encoded
  final String? packageDescription;

  CreatePackageModel({
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.paymentType,
    required this.amount,
    this.packageImage,
    this.packageDescription,
  });

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'delivery_address': deliveryAddress,
    if (deliveryLatitude != null) 'delivery_latitude': deliveryLatitude,
    if (deliveryLongitude != null) 'delivery_longitude': deliveryLongitude,
    'payment_type': paymentType,
    'amount': amount,
    if (packageImage != null && packageImage!.isNotEmpty)
      'package_image': packageImage,
    if (packageDescription != null && packageDescription!.isNotEmpty)
      'package_description': packageDescription,
  };
}
