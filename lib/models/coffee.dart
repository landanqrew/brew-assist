import 'package:json_annotation/json_annotation.dart';

part 'coffee.g.dart';

@JsonSerializable()
class Coffee {
  const Coffee({
    required this.id,
    required this.name,
    this.roasterId,
    this.origin,
    this.process,
    this.variety,
    this.description,
    this.tastingNotes,
    this.imageUrl,
    this.avgRating,
    this.checkInCount,
    this.createdBy,
    required this.createdAt,
  });

  factory Coffee.fromJson(Map<String, dynamic> json) =>
      _$CoffeeFromJson(json);

  final String id;

  final String name;

  @JsonKey(name: 'roaster_id')
  final String? roasterId;

  final String? origin;

  final String? process;

  final String? variety;

  final String? description;

  @JsonKey(name: 'tasting_notes')
  final String? tastingNotes;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'avg_rating')
  final double? avgRating;

  @JsonKey(name: 'check_in_count')
  final int? checkInCount;

  @JsonKey(name: 'created_by')
  final String? createdBy;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$CoffeeToJson(this);

  Coffee copyWith({
    String? id,
    String? name,
    String? roasterId,
    String? origin,
    String? process,
    String? variety,
    String? description,
    String? tastingNotes,
    String? imageUrl,
    double? avgRating,
    int? checkInCount,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Coffee(
      id: id ?? this.id,
      name: name ?? this.name,
      roasterId: roasterId ?? this.roasterId,
      origin: origin ?? this.origin,
      process: process ?? this.process,
      variety: variety ?? this.variety,
      description: description ?? this.description,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      avgRating: avgRating ?? this.avgRating,
      checkInCount: checkInCount ?? this.checkInCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coffee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Coffee(id: $id, name: $name)';
}
