// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckIn _$CheckInFromJson(Map<String, dynamic> json) => CheckIn(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  coffeeId: json['coffee_id'] as String,
  rating: (json['rating'] as num).toDouble(),
  notes: json['notes'] as String?,
  flavorTags: (json['flavor_tags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  brewMethod: json['brew_method'] as String?,
  servingStyle: json['serving_style'] as String?,
  photoUrl: json['photo_url'] as String?,
  venueType: json['venue_type'] as String?,
  specialtyDrink: json['specialty_drink'] as String?,
  venueId: json['venue_id'] as String?,
  grinderId: json['grinder_id'] as String?,
  grinderSetting: json['grinder_setting'] as String?,
  recipeId: json['recipe_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CheckInToJson(CheckIn instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'coffee_id': instance.coffeeId,
  'rating': instance.rating,
  'notes': instance.notes,
  'flavor_tags': instance.flavorTags,
  'brew_method': instance.brewMethod,
  'serving_style': instance.servingStyle,
  'photo_url': instance.photoUrl,
  'venue_type': instance.venueType,
  'specialty_drink': instance.specialtyDrink,
  'venue_id': instance.venueId,
  'grinder_id': instance.grinderId,
  'grinder_setting': instance.grinderSetting,
  'recipe_id': instance.recipeId,
  'created_at': instance.createdAt.toIso8601String(),
};
