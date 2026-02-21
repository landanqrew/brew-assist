import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/roaster.dart';
import '../../providers/coffee_provider.dart';
import '../../widgets/photo_picker_tile.dart';

/// Common coffee processing methods.
const _processOptions = [
  'Washed',
  'Natural',
  'Honey',
  'Anaerobic',
  'Wet-hulled',
  'Other',
];

/// Screen for adding a new coffee to the database.
///
/// Includes fields for name (required), roaster (existing dropdown or new
/// name), origin, process, variety, and description. On success, navigates
/// to the new coffee's detail page.
class AddCoffeeScreen extends ConsumerStatefulWidget {
  const AddCoffeeScreen({super.key});

  @override
  ConsumerState<AddCoffeeScreen> createState() => _AddCoffeeScreenState();
}

class _AddCoffeeScreenState extends ConsumerState<AddCoffeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _varietyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tastingNotesController = TextEditingController();
  final _newRoasterController = TextEditingController();

  String? _selectedProcess;
  Roaster? _selectedRoaster;
  bool _isNewRoaster = false;
  bool _isSubmitting = false;
  String? _imageUrl;
  String? _roasterLogoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _varietyController.dispose();
    _descriptionController.dispose();
    _tastingNotesController.dispose();
    _newRoasterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final coffeeId = await addCoffee(
        name: _nameController.text,
        roasterId: _isNewRoaster ? null : _selectedRoaster?.id,
        roasterName: _isNewRoaster ? _newRoasterController.text : null,
        roasterLogoUrl: _isNewRoaster ? _roasterLogoUrl : null,
        origin: _originController.text,
        process: _selectedProcess,
        variety: _varietyController.text,
        description: _descriptionController.text,
        tastingNotes: _tastingNotesController.text,
        imageUrl: _imageUrl,
      );

      if (!mounted) return;

      // Invalidate providers so lists refresh with the new coffee.
      ref.invalidate(coffeeListProvider);
      ref.invalidate(recentCoffeesProvider);
      ref.invalidate(roasterListProvider);

      // Navigate to the new coffee's detail page.
      context.go('/coffee/$coffeeId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add coffee: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roastersAsync = ref.watch(roasterListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Coffee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Name ──────────────────────────────────────────────────
            Text('Coffee Name *', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g., Worka Sakaro',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a coffee name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Roaster ───────────────────────────────────────────────
            Row(
              children: [
                Text('Roaster', style: AppTextStyles.labelLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isNewRoaster = !_isNewRoaster;
                      if (!_isNewRoaster) {
                        _newRoasterController.clear();
                        _roasterLogoUrl = null;
                      } else {
                        _selectedRoaster = null;
                      }
                    });
                  },
                  icon: Icon(
                    _isNewRoaster ? Icons.list : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    _isNewRoaster ? 'Choose existing' : 'Add new',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isNewRoaster) ...[
              TextFormField(
                controller: _newRoasterController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'New roaster name',
                ),
              ),
              const SizedBox(height: 12),
              PhotoPickerTile(
                folder: 'roasters',
                imageUrl: _roasterLogoUrl,
                onUploaded: (url) => setState(() => _roasterLogoUrl = url),
                label: 'Add Roaster Logo',
                height: 120,
              ),
            ] else
              roastersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(
                  'Could not load roasters',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
                data: (roasters) => DropdownButtonFormField<Roaster>(
                  value: _selectedRoaster,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select a roaster',
                  ),
                  items: roasters.map((roaster) {
                    return DropdownMenuItem(
                      value: roaster,
                      child: Text(
                        roaster.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRoaster = value);
                  },
                ),
              ),
            const SizedBox(height: 24),

            // ── Origin ────────────────────────────────────────────────
            Text('Origin', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _originController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g., Ethiopia, Yirgacheffe',
              ),
            ),
            const SizedBox(height: 24),

            // ── Process ───────────────────────────────────────────────
            Text('Process', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedProcess,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Select a process',
              ),
              items: _processOptions.map((process) {
                return DropdownMenuItem(
                  value: process,
                  child: Text(process),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedProcess = value);
              },
            ),
            const SizedBox(height: 24),

            // ── Variety ───────────────────────────────────────────────
            Text('Variety', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _varietyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g., Gesha, Bourbon, SL-28',
              ),
            ),
            const SizedBox(height: 24),

            // ── Tasting Notes ─────────────────────────────────────────
            Text('Tasting Notes', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tastingNotesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g., Blueberry, chocolate, jasmine',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────
            Text('Description', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Optional tasting notes or details...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // ── Photo ─────────────────────────────────────────────────
            Text('Photo', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            PhotoPickerTile(
              folder: 'coffees',
              imageUrl: _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
              label: 'Add Coffee Photo',
            ),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Add Coffee'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
