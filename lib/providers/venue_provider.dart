import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/venue.dart';

// ── Venue Search ────────────────────────────────────────────────────────────

/// Searches venues by name using case-insensitive partial matching.
final venueSearchProvider =
    FutureProvider.family<List<Venue>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final data = await supabase
      .from('venues')
      .select()
      .ilike('name', '%${query.trim()}%')
      .order('name', ascending: true)
      .limit(20);

  return (data as List).map((json) => Venue.fromJson(json)).toList();
});

// ── Add Venue ───────────────────────────────────────────────────────────────

/// Creates a new venue and returns it.
Future<Venue> addVenue({
  required String name,
  String? address,
}) async {
  final data = await supabase
      .from('venues')
      .insert({
        'name': name.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
      })
      .select()
      .single();

  return Venue.fromJson(data);
}
