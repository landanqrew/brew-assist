// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeStep _$RecipeStepFromJson(Map<String, dynamic> json) => RecipeStep(
  type: json['type'] as String,
  label: json['label'] as String,
  durationSec: (json['duration_sec'] as num?)?.toInt(),
  pressureBar: (json['pressure_bar'] as num?)?.toDouble(),
  waterMl: (json['water_ml'] as num?)?.toDouble(),
  pressureKg: (json['pressure_kg'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RecipeStepToJson(RecipeStep instance) =>
    <String, dynamic>{
      'type': instance.type,
      'label': instance.label,
      'duration_sec': instance.durationSec,
      'pressure_bar': instance.pressureBar,
      'water_ml': instance.waterMl,
      'pressure_kg': instance.pressureKg,
    };

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  title: json['title'] as String,
  brewMethod: json['brew_method'] as String,
  coffeeId: json['coffee_id'] as String?,
  doseGrams: (json['dose_grams'] as num?)?.toDouble(),
  waterMl: (json['water_ml'] as num?)?.toDouble(),
  yieldGrams: (json['yield_grams'] as num?)?.toDouble(),
  ratio: json['ratio'] as String?,
  grinderId: json['grinder_id'] as String?,
  grinderSetting: json['grinder_setting'] as String?,
  grindMicronsLow: (json['grind_microns_low'] as num?)?.toInt(),
  grindMicronsHigh: (json['grind_microns_high'] as num?)?.toInt(),
  grindLabel: json['grind_label'] as String?,
  waterTempC: (json['water_temp_c'] as num?)?.toDouble(),
  brewTimeSec: (json['brew_time_sec'] as num?)?.toInt(),
  steps: (json['steps'] as List<dynamic>?)
      ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  description: json['description'] as String?,
  forkedFrom: json['forked_from'] as String?,
  avgRating: (json['avg_rating'] as num?)?.toDouble(),
  saveCount: (json['save_count'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'title': instance.title,
  'brew_method': instance.brewMethod,
  'coffee_id': instance.coffeeId,
  'dose_grams': instance.doseGrams,
  'water_ml': instance.waterMl,
  'yield_grams': instance.yieldGrams,
  'ratio': instance.ratio,
  'grinder_id': instance.grinderId,
  'grinder_setting': instance.grinderSetting,
  'grind_microns_low': instance.grindMicronsLow,
  'grind_microns_high': instance.grindMicronsHigh,
  'grind_label': instance.grindLabel,
  'water_temp_c': instance.waterTempC,
  'brew_time_sec': instance.brewTimeSec,
  'steps': instance.steps,
  'description': instance.description,
  'forked_from': instance.forkedFrom,
  'avg_rating': instance.avgRating,
  'save_count': instance.saveCount,
  'created_at': instance.createdAt.toIso8601String(),
};
