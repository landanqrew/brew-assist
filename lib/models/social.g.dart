// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Follow _$FollowFromJson(Map<String, dynamic> json) => Follow(
  followerId: json['follower_id'] as String,
  followingId: json['following_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$FollowToJson(Follow instance) => <String, dynamic>{
  'follower_id': instance.followerId,
  'following_id': instance.followingId,
  'created_at': instance.createdAt.toIso8601String(),
};

Like _$LikeFromJson(Map<String, dynamic> json) => Like(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  targetType: json['target_type'] as String,
  targetId: json['target_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$LikeToJson(Like instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'target_type': instance.targetType,
  'target_id': instance.targetId,
  'created_at': instance.createdAt.toIso8601String(),
};

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  targetType: json['target_type'] as String,
  targetId: json['target_id'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'target_type': instance.targetType,
  'target_id': instance.targetId,
  'body': instance.body,
  'created_at': instance.createdAt.toIso8601String(),
};

SavedRecipe _$SavedRecipeFromJson(Map<String, dynamic> json) => SavedRecipe(
  userId: json['user_id'] as String,
  recipeId: json['recipe_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SavedRecipeToJson(SavedRecipe instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'recipe_id': instance.recipeId,
      'created_at': instance.createdAt.toIso8601String(),
    };
