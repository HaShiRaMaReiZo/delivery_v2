import 'package:json_annotation/json_annotation.dart';

part 'merchant_model.g.dart';

@JsonSerializable()
class MerchantModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'business_name')
  final String businessName;
  @JsonKey(name: 'business_address')
  final String? businessAddress;
  @JsonKey(name: 'business_phone')
  final String? businessPhone;
  @JsonKey(name: 'business_email')
  final String? businessEmail;
  @JsonKey(name: 'registration_number')
  final String? registrationNumber;
  @JsonKey(name: 'rating', fromJson: _ratingFromJson)
  final double? rating;
  @JsonKey(name: 'total_deliveries', fromJson: _intFromJson)
  final int? totalDeliveries;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
  final DateTime updatedAt;

  static DateTime _dateTimeFromJson(String dateString) {
    return DateTime.parse(dateString).toUtc();
  }

  static double? _ratingFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  MerchantModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.registrationNumber,
    this.rating,
    this.totalDeliveries,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) =>
      _$MerchantModelFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantModelToJson(this);
}
