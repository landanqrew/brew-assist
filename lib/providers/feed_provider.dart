import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../providers/auth_provider.dart';

// ── FeedItem Model ───────────────────────────────────────────────────────────

/// A composite model representing a single check-in in the feed, with all
/// joined data pre-parsed from the Supabase response.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.userId,
    required this.coffeeId,
    required this.rating,
    this.notes,
    this.flavorTags,
    this.brewMethod,
    this.servingStyle,
    this.photoUrl,
    required this.createdAt,
    // Profile fields
    this.username,
    this.displayName,
    this.avatarUrl,
    // Coffee fields
    this.coffeeName,
    this.coffeeOrigin,
    // Roaster fields
    this.roasterName,
    this.roasterId,
  });

  // ── Check-in data ────────────────────────────────────────────────────────
  final String id;
  final String userId;
  final String coffeeId;
  final double rating;
  final String? notes;
  final List<String>? flavorTags;
  final String? brewMethod;
  final String? servingStyle;
  final String? photoUrl;
  final DateTime createdAt;

  // ── Profile data ─────────────────────────────────────────────────────────
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  // ── Coffee data ──────────────────────────────────────────────────────────
  final String? coffeeName;
  final String? coffeeOrigin;

  // ── Roaster data ─────────────────────────────────────────────────────────
  final String? roasterName;
  final String? roasterId;

  /// Parses from the Supabase join response format:
  /// ```json
  /// {
  ///   "id": "...",
  ///   "profiles": { "username": "...", "display_name": "...", "avatar_url": "..." },
  ///   "coffees": { "name": "...", "origin": "...", "roasters": { "id": "...", "name": "..." } }
  /// }
  /// ```
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    final coffeeJson = json['coffees'] as Map<String, dynamic>?;
    final roasterJson = coffeeJson?['roasters'] as Map<String, dynamic>?;

    // Parse flavor_tags — Supabase returns text[] as a List<dynamic>.
    List<String>? flavorTags;
    if (json['flavor_tags'] != null) {
      flavorTags = (json['flavor_tags'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return FeedItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      coffeeId: json['coffee_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      notes: json['notes'] as String?,
      flavorTags: flavorTags,
      brewMethod: json['brew_method'] as String?,
      servingStyle: json['serving_style'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Profile
      username: profileJson?['username'] as String?,
      displayName: profileJson?['display_name'] as String?,
      avatarUrl: profileJson?['avatar_url'] as String?,
      // Coffee
      coffeeName: coffeeJson?['name'] as String?,
      coffeeOrigin: coffeeJson?['origin'] as String?,
      // Roaster
      roasterName: roasterJson?['name'] as String?,
      roasterId: roasterJson?['id'] as String?,
    );
  }
}

// ── Feed Provider ────────────────────────────────────────────────────────────

/// Fetches the most recent check-ins globally (for MVP, no follow filtering).
///
/// Joins profiles and coffees (with roasters) so that the feed UI has all the
/// data it needs in a single query.
final feedProvider = FutureProvider<List<FeedItem>>((ref) async {
  final data = await supabase
      .from('check_ins')
      .select('*, profiles(*), coffees(*, roasters(*))')
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List)
      .map((json) => FeedItem.fromJson(json as Map<String, dynamic>))
      .toList();
});

// ── User Check-ins Provider ──────────────────────────────────────────────────

/// A user-specific check-in item for the profile screen. Simpler than FeedItem
/// because we don't need profile data (it's the current user) but we do need
/// coffee + roaster info.
class UserCheckIn {
  const UserCheckIn({
    required this.id,
    required this.coffeeId,
    required this.rating,
    this.notes,
    this.flavorTags,
    this.brewMethod,
    this.servingStyle,
    required this.createdAt,
    this.coffeeName,
    this.roasterName,
  });

  final String id;
  final String coffeeId;
  final double rating;
  final String? notes;
  final List<String>? flavorTags;
  final String? brewMethod;
  final String? servingStyle;
  final DateTime createdAt;
  final String? coffeeName;
  final String? roasterName;

  factory UserCheckIn.fromJson(Map<String, dynamic> json) {
    final coffeeJson = json['coffees'] as Map<String, dynamic>?;
    final roasterJson = coffeeJson?['roasters'] as Map<String, dynamic>?;

    List<String>? flavorTags;
    if (json['flavor_tags'] != null) {
      flavorTags = (json['flavor_tags'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return UserCheckIn(
      id: json['id'] as String,
      coffeeId: json['coffee_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      notes: json['notes'] as String?,
      flavorTags: flavorTags,
      brewMethod: json['brew_method'] as String?,
      servingStyle: json['serving_style'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      coffeeName: coffeeJson?['name'] as String?,
      roasterName: roasterJson?['name'] as String?,
    );
  }
}

/// Fetches the current user's check-ins with coffee and roaster data.
///
/// Used on the profile screen to show real check-in history.
final userCheckInsProvider = FutureProvider<List<UserCheckIn>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId == null) return [];

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
