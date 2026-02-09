// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageModel _$PackageModelFromJson(Map<String, dynamic> json) => PackageModel(
  id: (json['id'] as num).toInt(),
  trackingCode: json['tracking_code'] as String?,
  merchantId: (json['merchant_id'] as num).toInt(),
  customerName: json['customer_name'] as String,
  customerPhone: json['customer_phone'] as String,
  deliveryAddress: json['delivery_address'] as String,
  deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
  deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
  paymentType: json['payment_type'] as String,
  amount: PackageModel._amountFromJson(json['amount']),
  packageImage: json['package_image'] as String?,
  packageDescription: json['package_description'] as String?,
  status: json['status'] as String?,
  registeredAt: PackageModel._dateTimeFromJsonNullable(
    json['registered_at'] as String?,
  ),
  deliveredAt: PackageModel._dateTimeFromJsonNullable(
    json['delivered_at'] as String?,
  ),
  createdAt: PackageModel._dateTimeFromJson(json['created_at'] as String),
  updatedAt: PackageModel._dateTimeFromJson(json['updated_at'] as String),
);

Map<String, dynamic> _$PackageModelToJson(PackageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tracking_code': instance.trackingCode,
      'merchant_id': instance.merchantId,
      'customer_name': instance.customerName,
      'customer_phone': instance.customerPhone,
      'delivery_address': instance.deliveryAddress,
      'delivery_latitude': instance.deliveryLatitude,
      'delivery_longitude': instance.deliveryLongitude,
      'payment_type': instance.paymentType,
      'amount': instance.amount,
      'package_image': instance.packageImage,
      'package_description': instance.packageDescription,
      'status': instance.status,
      'registered_at': instance.registeredAt?.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
