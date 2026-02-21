import 'package:json_annotation/json_annotation.dart';

part 'social.g.dart';

@JsonSerializable()
class Follow {
  const Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> json) =>
      _$FollowFromJson(json);

  @JsonKey(name: 'follower_id')
  final String followerId;

  @JsonKey(name: 'following_id')
  final String followingId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$FollowToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Follow &&
          runtimeType == other.runtimeType &&
          followerId == other.followerId &&
          followingId == other.followingId;

  @override
  int get hashCode => Object.hash(followerId, followingId);

  @override
  String toString() =>
      'Follow(followerId: $followerId, followingId: $followingId)';
}

@JsonSerializable()
class Like {
  const Like({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) => _$LikeFromJson(json);

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'target_type')
  final String targetType;

  @JsonKey(name: 'target_id')
  final String targetId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$LikeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Like && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Like(id: $id, targetType: $targetType, targetId: $targetId)';
}

@JsonSerializable()
class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.body,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'target_type')
  final String targetType;

  @JsonKey(name: 'target_id')
  final String targetId;

  final String body;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Comment(id: $id, body: $body)';
}

@JsonSerializable()
class SavedRecipe {
  const SavedRecipe({
    required this.userId,
    required this.recipeId,
    required this.createdAt,
  });

  factory SavedRecipe.fromJson(Map<String, dynamic> json) =>
      _$SavedRecipeFromJson(json);

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'recipe_id')
  final String recipeId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$SavedRecipeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRecipe &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          recipeId == other.recipeId;

  @override
  int get hashCode => Object.hash(userId, recipeId);

  @override
  String toString() =>
      'SavedRecipe(userId: $userId, recipeId: $recipeId)';
}
