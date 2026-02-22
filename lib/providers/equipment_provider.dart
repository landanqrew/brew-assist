import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/equipment.dart';
import '../providers/auth_provider.dart';

// ── Equipment Search ─────────────────────────────────────────────────────────

/// Search equipment_catalog by type + optional text query.
final equipmentSearchProvider = FutureProvider.family<List<EquipmentCatalog>,
    ({String type, String query})>((ref, params) async {
  var request = supabase
      .from('equipment_catalog')
      .select()
      .eq('type', params.type);

  if (params.query.trim().isNotEmpty) {
    final q = '%${params.query.trim()}%';
    request = request.or('brand.ilike.$q,model.ilike.$q');
  }

  final data = await request.order('brand', ascending: true).limit(30);

  return (data as List)
      .map((json) => EquipmentCatalog.fromJson(json))
      .toList();
});

// ── Equipment Detail ─────────────────────────────────────────────────────────

/// Fetch single equipment by ID.
final equipmentDetailProvider =
    FutureProvider.family<EquipmentCatalog, String>((ref, id) async {
  final data = await supabase
      .from('equipment_catalog')
      .select()
      .eq('id', id)
      .single();

  return EquipmentCatalog.fromJson(data);
});

// ── User Equipment by Type ───────────────────────────────────────────────────

/// Record pairing a UserEquipment row with its catalog entry.
class UserEquipmentWithCatalog {
  const UserEquipmentWithCatalog({
    required this.userEquipment,
    required this.catalog,
  });

  final UserEquipment userEquipment;
  final EquipmentCatalog catalog;
}

/// Current user's gear of a given type (for "My Gear" quick-select).
final userEquipmentByTypeProvider =
    FutureProvider.family<List<UserEquipmentWithCatalog>, String>(
        (ref, type) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return [];

  final data = await supabase
      .from('user_equipment')
      .select('*, equipment_catalog(*)')
      .eq('user_id', userId);

  final results = <UserEquipmentWithCatalog>[];
  for (final json in (data as List)) {
    final catalogJson = json['equipment_catalog'] as Map<String, dynamic>?;
    if (catalogJson == null) continue;

    final catalog = EquipmentCatalog.fromJson(catalogJson);
    if (catalog.type != type) continue;

    results.add(UserEquipmentWithCatalog(
      userEquipment: UserEquipment.fromJson(json),
      catalog: catalog,
    ));
  }

  // Primary gear first.
  results.sort((a, b) {
    final aPrimary = a.userEquipment.isPrimary == true ? 0 : 1;
    final bPrimary = b.userEquipment.isPrimary == true ? 0 : 1;
    return aPrimary.compareTo(bPrimary);
  });

  return results;
});
