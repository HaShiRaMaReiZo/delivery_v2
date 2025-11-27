import 'package:json_annotation/json_annotation.dart';

part 'package_status_history_model.g.dart';

@JsonSerializable()
class PackageStatusHistoryModel {
  final int id;
  @JsonKey(name: 'package_id')
  final int packageId;
  final String status;
  @JsonKey(name: 'changed_by_user_id')
  final int? changedByUserId;
  @JsonKey(name: 'changed_by_type')
  final String? changedByType;
  final String? notes;
  @JsonKey(fromJson: _coordinateFromJson)
  final double? latitude;
  @JsonKey(fromJson: _coordinateFromJson)
  final double? longitude;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;

  static DateTime _dateTimeFromJson(String dateString) {
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

  PackageStatusHistoryModel({
    required this.id,
    required this.packageId,
    required this.status,
    this.changedByUserId,
    this.changedByType,
    this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory PackageStatusHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$PackageStatusHistoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$PackageStatusHistoryModelToJson(this);
}
