import 'package:json_annotation/json_annotation.dart';

part 'rider_model.g.dart';

@JsonSerializable()
class RiderModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String name;
  final String phone;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  @JsonKey(name: 'vehicle_number')
  final String? vehicleNumber;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'zone_id')
  final int? zoneId;
  final String status;
  @JsonKey(name: 'rating', fromJson: _ratingFromJson)
  final double? rating;
  @JsonKey(name: 'total_deliveries')
  final int? totalDeliveries;
  @JsonKey(name: 'current_latitude', fromJson: _coordinateFromJson)
  final double? currentLatitude;
  @JsonKey(name: 'current_longitude', fromJson: _coordinateFromJson)
  final double? currentLongitude;
  @JsonKey(name: 'last_location_update')
  final DateTime? lastLocationUpdate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  RiderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.vehicleType,
    this.vehicleNumber,
    this.licenseNumber,
    this.zoneId,
    required this.status,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.rating,
    this.totalDeliveries,
    required this.createdAt,
    required this.updatedAt,
  });

  static double? _coordinateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static double? _ratingFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) =>
      _$RiderModelFromJson(json);
  Map<String, dynamic> toJson() => _$RiderModelToJson(this);
}
