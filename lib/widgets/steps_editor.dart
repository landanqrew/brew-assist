import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/recipe.dart';

/// Widget for building ordered timed steps in manual brew recipes.
class StepsEditor extends StatefulWidget {
  const StepsEditor({
    super.key,
    required this.steps,
    required this.onChanged,
  });

  final List<RecipeStep> steps;
  final ValueChanged<List<RecipeStep>> onChanged;

  @override
  State<StepsEditor> createState() => _StepsEditorState();
}

class _StepsEditorState extends State<StepsEditor> {
  void _addStep() => _showStepDialog();

  void _editStep(int index) => _showStepDialog(existingIndex: index);

  void _deleteStep(int index) {
    final updated = List<RecipeStep>.from(widget.steps)..removeAt(index);
    widget.onChanged(updated);
  }

  void _onReorder(int oldIndex, int newIndex) {
    final updated = List<RecipeStep>.from(widget.steps);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    widget.onChanged(updated);
  }

  Future<void> _showStepDialog({int? existingIndex}) async {
    final isEdit = existingIndex != null;
    final existing = isEdit ? widget.steps[existingIndex] : null;

    // Default time: last step + 30s, or 0:00 for first step.
    final defaultTime = widget.steps.isEmpty
        ? 0
        : widget.steps.last.stepTimeSec + 30;

    final timeController = TextEditingController(
      text: isEdit
          ? formatStepTime(existing!.stepTimeSec)
          : formatStepTime(defaultTime),
    );
    final descController = TextEditingController(
      text: existing?.description ?? '',
    );
    final waterController = TextEditingController(
      text: existing?.waterMl?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Step' : 'Add Step'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Time (m:ss) *',
                hintText: '0:30',
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g., Bloom with 50g water',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waterController,
              decoration: const InputDecoration(
                labelText: 'Water (ml)',
                hintText: 'Optional',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      timeController.dispose();
      descController.dispose();
      waterController.dispose();
      return;
    }

    final parsedTime = parseStepTime(timeController.text);
    final desc = descController.text.trim();

    timeController.dispose();
    descController.dispose();

    if (parsedTime == null || desc.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time and description are required.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      waterController.dispose();
      return;
    }

    final waterText = waterController.text.trim();
    waterController.dispose();
    final water =
        waterText.isNotEmpty ? double.tryParse(waterText) : null;

    final step = RecipeStep(
      stepTimeSec: parsedTime,
      description: desc,
      waterMl: water,
    );

    final updated = List<RecipeStep>.from(widget.steps);
    if (isEdit) {
      updated[existingIndex] = step;
    } else {
      updated.add(step);
    }

    // Keep sorted by time ascending.
    updated.sort((a, b) => a.stepTimeSec.compareTo(b.stepTimeSec));
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.steps.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.steps.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final step = widget.steps[index];
              return _StepCard(
                key: ValueKey('step_${step.stepTimeSec}_$index'),
                step: step,
                onEdit: () => _editStep(index),
                onDelete: () => _deleteStep(index),
              );
            },
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addStep,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Step'),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.step,
    required this.onEdit,
    required this.onDelete,
  });

  final RecipeStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Drag handle
            const Icon(Icons.drag_handle, color: AppColors.textSecondary),
            const SizedBox(width: 12),

            // Time badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formatStepTime(step.stepTimeSec),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Description + water
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.description, style: AppTextStyles.bodyMedium),
                  if (step.waterMl != null)
                    Text(
                      '${step.waterMl!.toStringAsFixed(0)} ml',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
