import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';

/// Shows a modal bottom sheet for selecting equipment from the catalog.
///
/// Returns the selected [EquipmentCatalog] or null if dismissed.
Future<EquipmentCatalog?> showEquipmentPicker(
  BuildContext context, {
  required String equipmentType,
  String? title,
}) {
  return showModalBottomSheet<EquipmentCatalog>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EquipmentPickerSheet(
      equipmentType: equipmentType,
      title: title ?? 'Select Equipment',
    ),
  );
}

class _EquipmentPickerSheet extends ConsumerStatefulWidget {
  const _EquipmentPickerSheet({
    required this.equipmentType,
    required this.title,
  });

  final String equipmentType;
  final String title;

  @override
  ConsumerState<_EquipmentPickerSheet> createState() =>
      _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState
    extends ConsumerState<_EquipmentPickerSheet> {
  String _searchQuery = '';
  Timer? _searchDebounce;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchQuery = query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final myGearAsync =
        ref.watch(userEquipmentByTypeProvider(widget.equipmentType));
    final searchAsync = ref.watch(equipmentSearchProvider(
      (type: widget.equipmentType, query: _searchQuery),
    ));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title + close
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by brand or model...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            // Results list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // My Gear section
                  myGearAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (myGear) {
                      if (myGear.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              'My Gear',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...myGear.map((item) => _EquipmentTile(
                                equipment: item.catalog,
                                isPrimary:
                                    item.userEquipment.isPrimary == true,
                                onTap: () =>
                                    Navigator.pop(context, item.catalog),
                              )),
                          const Divider(height: 24),
                        ],
                      );
                    },
                  ),

                  // All section
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      'All',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  searchAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Error: $error',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                    data: (results) {
                      if (results.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No equipment found.'
                                : 'No results for "$_searchQuery"',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: results
                            .map((eq) => _EquipmentTile(
                                  equipment: eq,
                                  onTap: () => Navigator.pop(context, eq),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({
    required this.equipment,
    required this.onTap,
    this.isPrimary = false,
  });

  final EquipmentCatalog equipment;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(
        '${equipment.brand} · ${equipment.model}',
        style: AppTextStyles.titleSmall,
      ),
      trailing: isPrimary
          ? Icon(Icons.star, size: 18, color: AppColors.primary)
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
