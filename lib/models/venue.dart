import 'package:json_annotation/json_annotation.dart';

part 'venue.g.dart';

@JsonSerializable()
class Venue {
  const Venue({
    required this.id,
    required this.name,
    this.address,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);

  final String id;

  final String name;

  final String? address;

  final double? lat;

  final double? lng;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$VenueToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Venue && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Venue(id: $id, name: $name)';
}
