// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_status_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageStatusHistoryModel _$PackageStatusHistoryModelFromJson(
  Map<String, dynamic> json,
) => PackageStatusHistoryModel(
  id: (json['id'] as num).toInt(),
  packageId: (json['package_id'] as num).toInt(),
  status: json['status'] as String,
  changedByUserId: (json['changed_by_user_id'] as num?)?.toInt(),
  changedByType: json['changed_by_type'] as String?,
  changedByName: json['changed_by_name'] as String?,
  notes: json['notes'] as String?,
  latitude: PackageStatusHistoryModel._coordinateFromJson(json['latitude']),
  longitude: PackageStatusHistoryModel._coordinateFromJson(json['longitude']),
  createdAt: PackageStatusHistoryModel._dateTimeFromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$PackageStatusHistoryModelToJson(
  PackageStatusHistoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'package_id': instance.packageId,
  'status': instance.status,
  'changed_by_user_id': instance.changedByUserId,
  'changed_by_type': instance.changedByType,
  'changed_by_name': instance.changedByName,
  'notes': instance.notes,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'created_at': instance.createdAt.toIso8601String(),
};
