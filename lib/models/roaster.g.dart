// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roaster.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Roaster _$RoasterFromJson(Map<String, dynamic> json) => Roaster(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String?,
  website: json['website'] as String?,
  logoUrl: json['logo_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RoasterToJson(Roaster instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'website': instance.website,
  'logo_url': instance.logoUrl,
  'created_at': instance.createdAt.toIso8601String(),
};
