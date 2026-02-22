import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/profile.dart';
import '../models/social.dart';
import '../providers/feed_provider.dart';

// ── Composite Model ──────────────────────────────────────────────────────────

/// A comment with its author's profile info, parsed from a Supabase join.
class CommentWithProfile {
  const CommentWithProfile({
    required this.comment,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  final Comment comment;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  factory CommentWithProfile.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    return CommentWithProfile(
      comment: Comment.fromJson(json),
      username: profileJson?['username'] as String? ?? '',
      displayName: profileJson?['display_name'] as String?,
      avatarUrl: profileJson?['avatar_url'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOLLOW PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Whether the current user follows the given [userId].
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return false;

  final data = await supabase
      .from('follows')
      .select('follower_id')
      .eq('follower_id', me)
      .eq('following_id', userId)
      .maybeSingle();

  return data != null;
});

/// Number of users that [userId] is following.
final followingCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final response = await supabase
      .from('follows')
      .select()
      .eq('follower_id', userId)
      .count();
  return response.count;
});

/// Number of followers for [userId].
final followerCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final response = await supabase
      .from('follows')
      .select()
      .eq('following_id', userId)
      .count();
  return response.count;
});

/// List of profiles that [userId] is following.
final followingListProvider =
    FutureProvider.family<List<Profile>, String>((ref, userId) async {
  final data = await supabase
      .from('follows')
      .select('profiles!follows_following_id_fkey(*)')
      .eq('follower_id', userId);

  return (data as List).map((row) {
    final profileJson = row['profiles'] as Map<String, dynamic>;
    return Profile.fromJson(profileJson);
  }).toList();
});

/// List of profiles that follow [userId].
final followerListProvider =
    FutureProvider.family<List<Profile>, String>((ref, userId) async {
  final data = await supabase
      .from('follows')
      .select('profiles!follows_follower_id_fkey(*)')
      .eq('following_id', userId);

  return (data as List).map((row) {
    final profileJson = row['profiles'] as Map<String, dynamic>;
    return Profile.fromJson(profileJson);
  }).toList();
});

/// IDs of users the current user follows. Used for feed filtering.
final followingIdsProvider = FutureProvider<List<String>>((ref) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return [];

  final data = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', me);

  return (data as List)
      .map((row) => row['following_id'] as String)
      .toList();
});

// ── Follow Notifier ──────────────────────────────────────────────────────────

class FollowNotifier extends StateNotifier<AsyncValue<void>> {
  FollowNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> follow(String userId) async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return;

    state = const AsyncLoading();
    try {
      await supabase.from('follows').insert({
        'follower_id': me,
        'following_id': userId,
      });
      state = const AsyncData(null);
      _invalidateFollowProviders(me, userId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> unfollow(String userId) async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return;

    state = const AsyncLoading();
    try {
      await supabase
          .from('follows')
          .delete()
          .eq('follower_id', me)
          .eq('following_id', userId);
      state = const AsyncData(null);
      _invalidateFollowProviders(me, userId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _invalidateFollowProviders(String me, String targetUserId) {
    _ref.invalidate(isFollowingProvider(targetUserId));
    _ref.invalidate(followingCountProvider(me));
    _ref.invalidate(followerCountProvider(targetUserId));
    _ref.invalidate(followingIdsProvider);
    _ref.invalidate(followingListProvider(me));
    _ref.invalidate(followerListProvider(targetUserId));
    _ref.invalidate(feedProvider);
  }
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, AsyncValue<void>>((ref) {
  return FollowNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// LIKE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

typedef LikeKey = ({String targetType, String targetId});

/// Number of likes for a given target.
final likeCountProvider =
    FutureProvider.family<int, LikeKey>((ref, key) async {
  final response = await supabase
      .from('likes')
      .select()
      .eq('target_type', key.targetType)
      .eq('target_id', key.targetId)
      .count();
  return response.count;
});

/// Whether the current user has liked the target.
final isLikedByMeProvider =
    FutureProvider.family<bool, LikeKey>((ref, key) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return false;

  final data = await supabase
      .from('likes')
      .select('id')
      .eq('user_id', me)
      .eq('target_type', key.targetType)
      .eq('target_id', key.targetId)
      .maybeSingle();

  return data != null;
});

// ── Like Notifier ────────────────────────────────────────────────────────────

class LikeNotifier extends StateNotifier<AsyncValue<void>> {
  LikeNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> toggleLike(String targetType, String targetId) async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return;

    final key = (targetType: targetType, targetId: targetId);
    final currentlyLiked =
        _ref.read(isLikedByMeProvider(key)).valueOrNull ?? false;

    try {
      if (currentlyLiked) {
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', me)
            .eq('target_type', targetType)
            .eq('target_id', targetId);
      } else {
        await supabase.from('likes').insert({
          'user_id': me,
          'target_type': targetType,
          'target_id': targetId,
        });
      }
      _ref.invalidate(isLikedByMeProvider(key));
      _ref.invalidate(likeCountProvider(key));
    } catch (_) {
      // Silently fail — the UI will stay in the previous state.
    }
  }
}

final likeNotifierProvider =
    StateNotifierProvider<LikeNotifier, AsyncValue<void>>((ref) {
  return LikeNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// COMMENT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

typedef CommentKey = ({String targetType, String targetId});

/// Comments for a given target, joined with profile data.
final commentsProvider =
    FutureProvider.family<List<CommentWithProfile>, CommentKey>(
        (ref, key) async {
  final data = await supabase
      .from('comments')
      .select('*, profiles(*)')
      .eq('target_type', key.targetType)
      .eq('target_id', key.targetId)
      .order('created_at', ascending: true);

  return (data as List)
      .map((json) =>
          CommentWithProfile.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Number of comments for a given target.
final commentCountProvider =
    FutureProvider.family<int, CommentKey>((ref, key) async {
  final response = await supabase
      .from('comments')
      .select()
      .eq('target_type', key.targetType)
      .eq('target_id', key.targetId)
      .count();
  return response.count;
});

// ── Comment Notifier ─────────────────────────────────────────────────────────

class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  CommentNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> addComment({
    required String targetType,
    required String targetId,
    required String body,
  }) async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return;

    try {
      await supabase.from('comments').insert({
        'user_id': me,
        'target_type': targetType,
        'target_id': targetId,
        'body': body,
      });
      final key = (targetType: targetType, targetId: targetId);
      _ref.invalidate(commentsProvider(key));
      _ref.invalidate(commentCountProvider(key));
    } catch (_) {}
  }

  Future<void> deleteComment({
    required String commentId,
    required String targetType,
    required String targetId,
  }) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
      final key = (targetType: targetType, targetId: targetId);
      _ref.invalidate(commentsProvider(key));
      _ref.invalidate(commentCountProvider(key));
    } catch (_) {}
  }
}

final commentNotifierProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  return CommentNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// USER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Fetch a single user's profile by ID.
final userProfileProvider =
    FutureProvider.family<Profile, String>((ref, userId) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  return Profile.fromJson(data);
});

/// Search for users by username or display name.
final userSearchProvider =
    FutureProvider.family<List<Profile>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final data = await supabase
      .from('profiles')
      .select()
      .or('username.ilike.%$query%,display_name.ilike.%$query%')
      .limit(20);

  return (data as List)
      .map((json) => Profile.fromJson(json as Map<String, dynamic>))
      .toList();
});

/// Fetch another user's check-ins (reuses UserCheckIn model from feed_provider).
final userCheckInsByIdProvider =
    FutureProvider.family<List<UserCheckIn>, String>((ref, userId) async {
  final data = await supabase
      .from('check_ins')
      .select('*, coffees(*, roasters(*))')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List)
      .map((json) => UserCheckIn.fromJson(json as Map<String, dynamic>))
      .toList();
});
