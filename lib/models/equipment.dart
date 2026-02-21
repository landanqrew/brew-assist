import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable()
class EquipmentCatalog {
  const EquipmentCatalog({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    this.customizations,
    this.imageUrl,
    this.grindRangeMin,
    this.grindRangeMax,
    this.grindSettings,
    this.createdBy,
    required this.createdAt,
  });

  factory EquipmentCatalog.fromJson(Map<String, dynamic> json) =>
      _$EquipmentCatalogFromJson(json);

  final String id;

  /// 'grinder', 'kettle', 'scale', 'brewer'
  final String type;

  final String brand;

  final String model;

  final String? customizations;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'grind_range_min')
  final int? grindRangeMin;

  @JsonKey(name: 'grind_range_max')
  final int? grindRangeMax;

  @JsonKey(name: 'grind_settings')
  final Map<String, dynamic>? grindSettings;

  @JsonKey(name: 'created_by')
  final String? createdBy;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$EquipmentCatalogToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentCatalog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EquipmentCatalog(id: $id, type: $type, brand: $brand, model: $model)';
}

@JsonSerializable()
class UserEquipment {
  const UserEquipment({
    required this.id,
    required this.userId,
    required this.equipmentId,
    this.nickname,
    this.isPrimary,
    this.rating,
    required this.createdAt,
  });

  factory UserEquipment.fromJson(Map<String, dynamic> json) =>
      _$UserEquipmentFromJson(json);

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'equipment_id')
  final String equipmentId;

  final String? nickname;

  @JsonKey(name: 'is_primary')
  final bool? isPrimary;

  final double? rating;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$UserEquipmentToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEquipment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserEquipment(id: $id, equipmentId: $equipmentId, nickname: $nickname)';
}
