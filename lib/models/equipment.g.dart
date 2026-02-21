// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EquipmentCatalog _$EquipmentCatalogFromJson(Map<String, dynamic> json) =>
    EquipmentCatalog(
      id: json['id'] as String,
      type: json['type'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      customizations: json['customizations'] as String?,
      imageUrl: json['image_url'] as String?,
      grindRangeMin: (json['grind_range_min'] as num?)?.toInt(),
      grindRangeMax: (json['grind_range_max'] as num?)?.toInt(),
      grindSettings: json['grind_settings'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$EquipmentCatalogToJson(EquipmentCatalog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'brand': instance.brand,
      'model': instance.model,
      'customizations': instance.customizations,
      'image_url': instance.imageUrl,
      'grind_range_min': instance.grindRangeMin,
      'grind_range_max': instance.grindRangeMax,
      'grind_settings': instance.grindSettings,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };

UserEquipment _$UserEquipmentFromJson(Map<String, dynamic> json) =>
    UserEquipment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      equipmentId: json['equipment_id'] as String,
      nickname: json['nickname'] as String?,
      isPrimary: json['is_primary'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserEquipmentToJson(UserEquipment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'equipment_id': instance.equipmentId,
      'nickname': instance.nickname,
      'is_primary': instance.isPrimary,
      'rating': instance.rating,
      'created_at': instance.createdAt.toIso8601String(),
    };
