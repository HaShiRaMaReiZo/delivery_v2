// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantModel _$MerchantModelFromJson(Map<String, dynamic> json) =>
    MerchantModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      businessName: json['business_name'] as String,
      businessAddress: json['business_address'] as String?,
      businessPhone: json['business_phone'] as String?,
      businessEmail: json['business_email'] as String?,
      registrationNumber: json['registration_number'] as String?,
      rating: MerchantModel._ratingFromJson(json['rating']),
      totalDeliveries: MerchantModel._intFromJson(json['total_deliveries']),
      createdAt: MerchantModel._dateTimeFromJson(json['created_at'] as String),
      updatedAt: MerchantModel._dateTimeFromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$MerchantModelToJson(MerchantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'business_name': instance.businessName,
      'business_address': instance.businessAddress,
      'business_phone': instance.businessPhone,
      'business_email': instance.businessEmail,
      'registration_number': instance.registrationNumber,
      'rating': instance.rating,
      'total_deliveries': instance.totalDeliveries,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
