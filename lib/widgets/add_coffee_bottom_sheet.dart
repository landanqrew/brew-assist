import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/coffee_provider.dart';
import 'photo_picker_tile.dart';

/// Result returned when a coffee is created from the bottom sheet.
class AddCoffeeResult {
  const AddCoffeeResult({required this.id, required this.name});

  final String id;
  final String name;
}

/// Shows a modal bottom sheet for quickly adding a new coffee inline.
///
/// Returns an [AddCoffeeResult] if a coffee was created, or null if cancelled.
Future<AddCoffeeResult?> showAddCoffeeBottomSheet(
  BuildContext context, {
  String? roasterId,
  String? roasterName,
}) {
  return showModalBottomSheet<AddCoffeeResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddCoffeeSheet(
      roasterId: roasterId,
      roasterName: roasterName,
    ),
  );
}

class _AddCoffeeSheet extends ConsumerStatefulWidget {
  const _AddCoffeeSheet({this.roasterId, this.roasterName});

  final String? roasterId;
  final String? roasterName;

  @override
  ConsumerState<_AddCoffeeSheet> createState() => _AddCoffeeSheetState();
}

class _AddCoffeeSheetState extends ConsumerState<_AddCoffeeSheet> {
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _processController = TextEditingController();
  final _varietyController = TextEditingController();
  final _tastingNotesController = TextEditingController();
  bool _isSubmitting = false;
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _processController.dispose();
    _varietyController.dispose();
    _tastingNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final coffeeId = await addCoffee(
        name: name,
        roasterId: widget.roasterId,
        origin: _originController.text,
        process: _processController.text,
        variety: _varietyController.text,
        tastingNotes: _tastingNotesController.text,
        imageUrl: _imageUrl,
      );

      if (mounted) {
        Navigator.pop(
          context,
          AddCoffeeResult(id: coffeeId, name: name),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add coffee: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Add Coffee', style: AppTextStyles.titleMedium),
          if (widget.roasterName != null) ...[
            const SizedBox(height: 4),
            Text(
              'for ${widget.roasterName}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Coffee Name (required)
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Coffee Name *',
              hintText: 'e.g., Worka Sakaro',
            ),
          ),
          const SizedBox(height: 12),

          // Origin
          TextField(
            controller: _originController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Origin',
              hintText: 'e.g., Ethiopia, Yirgacheffe',
            ),
          ),
          const SizedBox(height: 12),

          // Process
          TextField(
            controller: _processController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Process',
              hintText: 'e.g., Washed, Natural',
            ),
          ),
          const SizedBox(height: 12),

          // Variety
          TextField(
            controller: _varietyController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Variety',
              hintText: 'e.g., Gesha, Bourbon',
            ),
          ),
          const SizedBox(height: 12),

          // Tasting Notes
          TextField(
            controller: _tastingNotesController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Tasting Notes',
              hintText: 'e.g., Blueberry, chocolate, jasmine',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // Photo
          PhotoPickerTile(
            folder: 'coffees',
            imageUrl: _imageUrl,
            onUploaded: (url) => setState(() => _imageUrl = url),
            label: 'Add Coffee Photo',
            height: 120,
          ),
          const SizedBox(height: 20),

          // Submit
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
        ],
      ),
    );
  }
}
