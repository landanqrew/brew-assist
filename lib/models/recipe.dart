import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

@JsonSerializable()
class RecipeStep {
  const RecipeStep({
    required this.type,
    required this.label,
    this.durationSec,
    this.pressureBar,
    this.waterMl,
    this.pressureKg,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);

  /// "prep" or "brew"
  final String type;

  final String label;

  @JsonKey(name: 'duration_sec')
  final int? durationSec;

  @JsonKey(name: 'pressure_bar')
  final double? pressureBar;

  @JsonKey(name: 'water_ml')
  final double? waterMl;

  @JsonKey(name: 'pressure_kg')
  final double? pressureKg;

  Map<String, dynamic> toJson() => _$RecipeStepToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeStep &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          label == other.label &&
          durationSec == other.durationSec &&
          pressureBar == other.pressureBar &&
          waterMl == other.waterMl &&
          pressureKg == other.pressureKg;

  @override
  int get hashCode => Object.hash(type, label, durationSec, pressureBar, waterMl, pressureKg);

  @override
  String toString() => 'RecipeStep(type: $type, label: $label)';
}

@JsonSerializable()
class Recipe {
  const Recipe({
    required this.id,
    required this.userId,
    required this.title,
    required this.brewMethod,
    this.coffeeId,
    this.doseGrams,
    this.waterMl,
    this.yieldGrams,
    this.ratio,
    this.grinderId,
    this.grinderSetting,
    this.grindMicronsLow,
    this.grindMicronsHigh,
    this.grindLabel,
    this.waterTempC,
    this.brewTimeSec,
    this.steps,
    this.description,
    this.forkedFrom,
    this.avgRating,
    this.saveCount,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      _$RecipeFromJson(json);

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String title;

  @JsonKey(name: 'brew_method')
  final String brewMethod;

  @JsonKey(name: 'coffee_id')
  final String? coffeeId;

  @JsonKey(name: 'dose_grams')
  final double? doseGrams;

  @JsonKey(name: 'water_ml')
  final double? waterMl;

  @JsonKey(name: 'yield_grams')
  final double? yieldGrams;

  final String? ratio;

  @JsonKey(name: 'grinder_id')
  final String? grinderId;

  @JsonKey(name: 'grinder_setting')
  final String? grinderSetting;

  @JsonKey(name: 'grind_microns_low')
  final int? grindMicronsLow;

  @JsonKey(name: 'grind_microns_high')
  final int? grindMicronsHigh;

  @JsonKey(name: 'grind_label')
  final String? grindLabel;

  @JsonKey(name: 'water_temp_c')
  final double? waterTempC;

  @JsonKey(name: 'brew_time_sec')
  final int? brewTimeSec;

  final List<RecipeStep>? steps;

  final String? description;

  @JsonKey(name: 'forked_from')
  final String? forkedFrom;

  @JsonKey(name: 'avg_rating')
  final double? avgRating;

  @JsonKey(name: 'save_count')
  final int? saveCount;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$RecipeToJson(this);

  Recipe copyWith({
    String? id,
    String? userId,
    String? title,
    String? brewMethod,
    String? coffeeId,
    double? doseGrams,
    double? waterMl,
    double? yieldGrams,
    String? ratio,
    String? grinderId,
    String? grinderSetting,
    int? grindMicronsLow,
    int? grindMicronsHigh,
    String? grindLabel,
    double? waterTempC,
    int? brewTimeSec,
    List<RecipeStep>? steps,
    String? description,
    String? forkedFrom,
    double? avgRating,
    int? saveCount,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      brewMethod: brewMethod ?? this.brewMethod,
      coffeeId: coffeeId ?? this.coffeeId,
      doseGrams: doseGrams ?? this.doseGrams,
      waterMl: waterMl ?? this.waterMl,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      ratio: ratio ?? this.ratio,
      grinderId: grinderId ?? this.grinderId,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      grindMicronsLow: grindMicronsLow ?? this.grindMicronsLow,
      grindMicronsHigh: grindMicronsHigh ?? this.grindMicronsHigh,
      grindLabel: grindLabel ?? this.grindLabel,
      waterTempC: waterTempC ?? this.waterTempC,
      brewTimeSec: brewTimeSec ?? this.brewTimeSec,
      steps: steps ?? this.steps,
      description: description ?? this.description,
      forkedFrom: forkedFrom ?? this.forkedFrom,
      avgRating: avgRating ?? this.avgRating,
      saveCount: saveCount ?? this.saveCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Recipe(id: $id, title: $title, brewMethod: $brewMethod)';
}
