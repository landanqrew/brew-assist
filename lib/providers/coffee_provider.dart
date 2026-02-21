import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/coffee.dart';
import '../models/roaster.dart';

// ── Coffee List ─────────────────────────────────────────────────────────────

/// Fetches all coffees from Supabase, ordered by name.
///
/// Includes the related roaster via a join. The result is a list of
/// [CoffeeWithRoaster] records so the UI can display roaster info without
/// a second query.
final coffeeListProvider = FutureProvider<List<CoffeeWithRoaster>>((ref) async {
  final data = await supabase
      .from('coffees')
      .select('*, roasters(*)')
      .order('name', ascending: true);

  return (data as List).map((json) => CoffeeWithRoaster.fromJson(json)).toList();
});

// ── Coffee Search ───────────────────────────────────────────────────────────

/// Searches coffees by name using case-insensitive partial matching.
///
/// Returns an empty list for blank queries.
final coffeeSearchProvider =
    FutureProvider.family<List<CoffeeWithRoaster>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final data = await supabase
      .from('coffees')
      .select('*, roasters(*)')
      .ilike('name', '%${query.trim()}%')
      .order('name', ascending: true)
      .limit(30);

  return (data as List).map((json) => CoffeeWithRoaster.fromJson(json)).toList();
});

// ── Recently Added Coffees ──────────────────────────────────────────────────

/// Fetches the most recently added coffees for the discovery view.
final recentCoffeesProvider =
    FutureProvider<List<CoffeeWithRoaster>>((ref) async {
  final data = await supabase
      .from('coffees')
      .select('*, roasters(*)')
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List).map((json) => CoffeeWithRoaster.fromJson(json)).toList();
});

// ── Coffee Detail ───────────────────────────────────────────────────────────

/// Fetches a single coffee by ID with its roaster data.
final coffeeDetailProvider =
    FutureProvider.family<CoffeeWithRoaster, String>((ref, id) async {
  final data = await supabase
      .from('coffees')
      .select('*, roasters(*)')
      .eq('id', id)
      .single();

  return CoffeeWithRoaster.fromJson(data);
});

// ── Coffee Check-ins ────────────────────────────────────────────────────────

/// Fetches recent check-ins for a specific coffee, with profile data joined.
final coffeeCheckInsProvider =
    FutureProvider.family<List<CheckInWithProfile>, String>((ref, coffeeId) async {
  final data = await supabase
      .from('check_ins')
      .select('*, profiles(*)')
      .eq('coffee_id', coffeeId)
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List)
      .map((json) => CheckInWithProfile.fromJson(json))
      .toList();
});

// ── Roaster List ────────────────────────────────────────────────────────────

/// Fetches all roasters, ordered by name, for the "add coffee" form dropdown.
final roasterListProvider = FutureProvider<List<Roaster>>((ref) async {
  final data = await supabase
      .from('roasters')
      .select()
      .order('name', ascending: true);

  return (data as List).map((json) => Roaster.fromJson(json)).toList();
});

// ── Add Coffee ──────────────────────────────────────────────────────────────

/// Inserts a new coffee into the database.
///
/// If [roasterName] is provided instead of [roasterId], a new roaster is
/// created first and its ID is used.
///
/// Returns the ID of the newly created coffee.
Future<String> addCoffee({
  required String name,
  String? roasterId,
  String? roasterName,
  String? origin,
  String? process,
  String? variety,
  String? description,
}) async {
  final userId = supabase.auth.currentUser?.id;

  // If a new roaster name was provided, create it first.
  String? finalRoasterId = roasterId;
  if (finalRoasterId == null && roasterName != null && roasterName.trim().isNotEmpty) {
    final roasterData = await supabase
        .from('roasters')
        .insert({'name': roasterName.trim()})
        .select('id')
        .single();
    finalRoasterId = roasterData['id'] as String;
  }

  final coffeeData = await supabase
      .from('coffees')
      .insert({
        'name': name.trim(),
        if (finalRoasterId != null) 'roaster_id': finalRoasterId,
        if (origin != null && origin.trim().isNotEmpty) 'origin': origin.trim(),
        if (process != null && process.trim().isNotEmpty) 'process': process.trim(),
        if (variety != null && variety.trim().isNotEmpty) 'variety': variety.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (userId != null) 'created_by': userId,
      })
      .select('id')
      .single();

  return coffeeData['id'] as String;
}

// ── Composite Models ────────────────────────────────────────────────────────

/// A coffee together with its optionally joined roaster data.
class CoffeeWithRoaster {
  const CoffeeWithRoaster({
    required this.coffee,
    this.roaster,
  });

  final Coffee coffee;
  final Roaster? roaster;

  factory CoffeeWithRoaster.fromJson(Map<String, dynamic> json) {
    // The roaster data comes as a nested object under the 'roasters' key
    // from the Supabase join query `select('*, roasters(*)')`.
    final roasterJson = json['roasters'] as Map<String, dynamic>?;

    return CoffeeWithRoaster(
      coffee: Coffee.fromJson(json),
      roaster: roasterJson != null ? Roaster.fromJson(roasterJson) : null,
    );
  }
}

/// A check-in together with its profile data.
class CheckInWithProfile {
  const CheckInWithProfile({
    required this.id,
    required this.userId,
    required this.coffeeId,
    required this.rating,
    this.notes,
    this.brewMethod,
    this.servingStyle,
    this.photoUrl,
    required this.createdAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String coffeeId;
  final double rating;
  final String? notes;
  final String? brewMethod;
  final String? servingStyle;
  final String? photoUrl;
  final DateTime createdAt;

  // Profile fields
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  factory CheckInWithProfile.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;

    return CheckInWithProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      coffeeId: json['coffee_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      notes: json['notes'] as String?,
      brewMethod: json['brew_method'] as String?,
      servingStyle: json['serving_style'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: profileJson?['username'] as String?,
      displayName: profileJson?['display_name'] as String?,
      avatarUrl: profileJson?['avatar_url'] as String?,
    );
  }
}
