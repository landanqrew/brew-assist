import 'package:json_annotation/json_annotation.dart';

part 'roaster.g.dart';

@JsonSerializable()
class Roaster {
  const Roaster({
    required this.id,
    required this.name,
    this.location,
    this.website,
    this.logoUrl,
    required this.createdAt,
  });

  factory Roaster.fromJson(Map<String, dynamic> json) =>
      _$RoasterFromJson(json);

  final String id;

  final String name;

  final String? location;

  final String? website;

  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$RoasterToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Roaster && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Roaster(id: $id, name: $name)';
}
