// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rider_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiderModel _$RiderModelFromJson(Map<String, dynamic> json) => RiderModel(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  name: json['name'] as String,
  phone: json['phone'] as String,
  vehicleType: json['vehicle_type'] as String?,
  vehicleNumber: json['vehicle_number'] as String?,
  licenseNumber: json['license_number'] as String?,
  zoneId: (json['zone_id'] as num?)?.toInt(),
  status: json['status'] as String,
  currentLatitude: RiderModel._coordinateFromJson(json['current_latitude']),
  currentLongitude: RiderModel._coordinateFromJson(json['current_longitude']),
  lastLocationUpdate: json['last_location_update'] == null
      ? null
      : DateTime.parse(json['last_location_update'] as String),
  rating: RiderModel._ratingFromJson(json['rating']),
  totalDeliveries: (json['total_deliveries'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RiderModelToJson(RiderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'phone': instance.phone,
      'vehicle_type': instance.vehicleType,
      'vehicle_number': instance.vehicleNumber,
      'license_number': instance.licenseNumber,
      'zone_id': instance.zoneId,
      'status': instance.status,
      'rating': instance.rating,
      'total_deliveries': instance.totalDeliveries,
      'current_latitude': instance.currentLatitude,
      'current_longitude': instance.currentLongitude,
      'last_location_update': instance.lastLocationUpdate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
