// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coffee _$CoffeeFromJson(Map<String, dynamic> json) => Coffee(
  id: json['id'] as String,
  name: json['name'] as String,
  roasterId: json['roaster_id'] as String?,
  origin: json['origin'] as String?,
  process: json['process'] as String?,
  variety: json['variety'] as String?,
  description: json['description'] as String?,
  tastingNotes: json['tasting_notes'] as String?,
  imageUrl: json['image_url'] as String?,
  avgRating: (json['avg_rating'] as num?)?.toDouble(),
  checkInCount: (json['check_in_count'] as num?)?.toInt(),
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CoffeeToJson(Coffee instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'roaster_id': instance.roasterId,
  'origin': instance.origin,
  'process': instance.process,
  'variety': instance.variety,
  'description': instance.description,
  'tasting_notes': instance.tastingNotes,
  'image_url': instance.imageUrl,
  'avg_rating': instance.avgRating,
  'check_in_count': instance.checkInCount,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
};
