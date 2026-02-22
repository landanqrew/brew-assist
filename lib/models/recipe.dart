import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

// ── Brew Method Classification ───────────────────────────────────────────────

enum BrewMethodCategory { espresso, manual }

BrewMethodCategory classifyBrewMethod(String method) {
  if (method == 'Espresso') return BrewMethodCategory.espresso;
  return BrewMethodCategory.manual;
}

const brewMethods = [
  'Espresso',
  'Pour-Over',
  'French Press',
  'AeroPress',
  'Chemex',
  'Moka Pot',
  'Cold Brew',
  'Auto-Dripper',
  'Siphon',
  'Other',
];

// ── Recipe Step ──────────────────────────────────────────────────────────────

@JsonSerializable()
class RecipeStep {
  const RecipeStep({
    required this.stepTimeSec,
    required this.description,
    this.waterMl,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);

  @JsonKey(name: 'step_time')
  final int stepTimeSec;

  final String description;

  @JsonKey(name: 'water_ml')
  final double? waterMl;

  Map<String, dynamic> toJson() => _$RecipeStepToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeStep &&
          runtimeType == other.runtimeType &&
          stepTimeSec == other.stepTimeSec &&
          description == other.description &&
          waterMl == other.waterMl;

  @override
  int get hashCode => Object.hash(stepTimeSec, description, waterMl);

  @override
  String toString() =>
      'RecipeStep(stepTimeSec: $stepTimeSec, description: $description)';
}

// ── Time Helpers ─────────────────────────────────────────────────────────────

String formatStepTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

int? parseStepTime(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split(':');
  if (parts.length == 2) {
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m != null && s != null && s >= 0 && s < 60) return m * 60 + s;
    return null;
  }

  return int.tryParse(trimmed);
}

// ── Recipe ───────────────────────────────────────────────────────────────────

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
    this.brewerId,
    this.distributionMethod,
    this.tampPressureKg,
    this.preInfusionSec,
    this.maxPressureBar,
    this.milkNotes,
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

  // ── Espresso-specific fields ─────────────────────────────────────────────

  @JsonKey(name: 'brewer_id')
  final String? brewerId;

  @JsonKey(name: 'distribution_method')
  final String? distributionMethod;

  @JsonKey(name: 'tamp_pressure_kg')
  final double? tampPressureKg;

  @JsonKey(name: 'pre_infusion_sec')
  final int? preInfusionSec;

  @JsonKey(name: 'max_pressure_bar')
  final double? maxPressureBar;

  @JsonKey(name: 'milk_notes')
  final String? milkNotes;

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
    String? brewerId,
    String? distributionMethod,
    double? tampPressureKg,
    int? preInfusionSec,
    double? maxPressureBar,
    String? milkNotes,
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
      brewerId: brewerId ?? this.brewerId,
      distributionMethod: distributionMethod ?? this.distributionMethod,
      tampPressureKg: tampPressureKg ?? this.tampPressureKg,
      preInfusionSec: preInfusionSec ?? this.preInfusionSec,
      maxPressureBar: maxPressureBar ?? this.maxPressureBar,
      milkNotes: milkNotes ?? this.milkNotes,
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
