import 'package:json_annotation/json_annotation.dart';

part 'check_in.g.dart';

@JsonSerializable()
class CheckIn {
  const CheckIn({
    required this.id,
    required this.userId,
    required this.coffeeId,
    required this.rating,
    this.notes,
    this.flavorTags,
    this.brewMethod,
    this.servingStyle,
    this.photoUrl,
    this.venueType,
    this.specialtyDrink,
    this.venueId,
    this.grinderId,
    this.grinderSetting,
    required this.createdAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) =>
      _$CheckInFromJson(json);

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'coffee_id')
  final String coffeeId;

  final double rating;

  final String? notes;

  @JsonKey(name: 'flavor_tags')
  final List<String>? flavorTags;

  @JsonKey(name: 'brew_method')
  final String? brewMethod;

  @JsonKey(name: 'serving_style')
  final String? servingStyle;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  @JsonKey(name: 'venue_type')
  final String? venueType;

  @JsonKey(name: 'specialty_drink')
  final String? specialtyDrink;

  @JsonKey(name: 'venue_id')
  final String? venueId;

  @JsonKey(name: 'grinder_id')
  final String? grinderId;

  @JsonKey(name: 'grinder_setting')
  final String? grinderSetting;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$CheckInToJson(this);

  CheckIn copyWith({
    String? id,
    String? userId,
    String? coffeeId,
    double? rating,
    String? notes,
    List<String>? flavorTags,
    String? brewMethod,
    String? servingStyle,
    String? photoUrl,
    String? venueType,
    String? specialtyDrink,
    String? venueId,
    String? grinderId,
    String? grinderSetting,
    DateTime? createdAt,
  }) {
    return CheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coffeeId: coffeeId ?? this.coffeeId,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      flavorTags: flavorTags ?? this.flavorTags,
      brewMethod: brewMethod ?? this.brewMethod,
      servingStyle: servingStyle ?? this.servingStyle,
      photoUrl: photoUrl ?? this.photoUrl,
      venueType: venueType ?? this.venueType,
      specialtyDrink: specialtyDrink ?? this.specialtyDrink,
      venueId: venueId ?? this.venueId,
      grinderId: grinderId ?? this.grinderId,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckIn && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CheckIn(id: $id, coffeeId: $coffeeId, rating: $rating)';
}
