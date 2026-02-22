import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/equipment.dart';
import '../../models/recipe.dart';
import '../../providers/coffee_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/equipment_picker_sheet.dart';
import '../../widgets/steps_editor.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _distributionMethods = [
  'WDT',
  'OCD',
  'Shaker',
  'Leveler',
  'Palm Tap',
  'None',
];

// ── Recipe Form Screen ───────────────────────────────────────────────────────

class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({
    super.key,
    this.recipeId,
    this.forkedFromId,
  });

  final String? recipeId;
  final String? forkedFromId;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  bool get _isEdit => widget.recipeId != null;
  bool get _isFork => widget.forkedFromId != null;

  // ── Common fields ────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  String? _brewMethod;
  String? _selectedCoffeeId;
  String? _selectedCoffeeName;
  String _coffeeSearchQuery = '';
  Timer? _coffeeSearchDebounce;
  final _coffeeSearchController = TextEditingController();

  EquipmentCatalog? _selectedGrinder;
  final _grinderSettingController = TextEditingController();
  final _doseController = TextEditingController();
  final _ratioController = TextEditingController();

  // ── Espresso fields ──────────────────────────────────────────────────────
  EquipmentCatalog? _selectedMachine;
  String? _distributionMethod;
  final _tampPressureController = TextEditingController();
  final _brewTempController = TextEditingController();
  final _preInfusionController = TextEditingController();
  final _maxPressureController = TextEditingController();
  final _yieldController = TextEditingController();
  final _shotDurationController = TextEditingController();
  final _shotNotesController = TextEditingController();
  final _milkNotesController = TextEditingController();

  // ── Manual fields ────────────────────────────────────────────────────────
  EquipmentCatalog? _selectedBrewer;
  final _manualBrewTempController = TextEditingController();
  final _waterAmountController = TextEditingController();
  final _totalBrewTimeController = TextEditingController();
  List<RecipeStep> _steps = [];
  final _brewNotesController = TextEditingController();

  bool _loaded = false;

  BrewMethodCategory? get _category =>
      _brewMethod != null ? classifyBrewMethod(_brewMethod!) : null;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && _brewMethod != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit || _isFork) {
      _loadExistingRecipe(_isEdit ? widget.recipeId! : widget.forkedFromId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coffeeSearchController.dispose();
    _coffeeSearchDebounce?.cancel();
    _grinderSettingController.dispose();
    _doseController.dispose();
    _ratioController.dispose();
    _tampPressureController.dispose();
    _brewTempController.dispose();
    _preInfusionController.dispose();
    _maxPressureController.dispose();
    _yieldController.dispose();
    _shotDurationController.dispose();
    _shotNotesController.dispose();
    _milkNotesController.dispose();
    _manualBrewTempController.dispose();
    _waterAmountController.dispose();
    _totalBrewTimeController.dispose();
    _brewNotesController.dispose();
    super.dispose();
  }

  // ── Load existing recipe ─────────────────────────────────────────────────

  Future<void> _loadExistingRecipe(String id) async {
    try {
      final recipe = await ref.read(recipeDetailProvider(id).future);
      if (!mounted) return;
      setState(() {
        _titleController.text = _isFork ? '${recipe.title} (fork)' : recipe.title;
        _brewMethod = recipe.brewMethod;
        _selectedCoffeeId = recipe.coffeeId;
        _grinderSettingController.text = recipe.grinderSetting ?? '';
        _doseController.text = recipe.doseGrams?.toString() ?? '';
        _ratioController.text = recipe.ratio ?? '';

        if (classifyBrewMethod(recipe.brewMethod) ==
            BrewMethodCategory.espresso) {
          _distributionMethod = recipe.distributionMethod;
          _tampPressureController.text =
              recipe.tampPressureKg?.toString() ?? '';
          _brewTempController.text = recipe.waterTempC?.toString() ?? '';
          _preInfusionController.text =
              recipe.preInfusionSec?.toString() ?? '';
          _maxPressureController.text =
              recipe.maxPressureBar?.toString() ?? '';
          _yieldController.text = recipe.yieldGrams?.toString() ?? '';
          _shotDurationController.text =
              recipe.brewTimeSec?.toString() ?? '';
          _shotNotesController.text = recipe.description ?? '';
          _milkNotesController.text = recipe.milkNotes ?? '';
        } else {
          _manualBrewTempController.text =
              recipe.waterTempC?.toString() ?? '';
          _waterAmountController.text = recipe.waterMl?.toString() ?? '';
          _totalBrewTimeController.text =
              recipe.brewTimeSec?.toString() ?? '';
          _steps = List<RecipeStep>.from(recipe.steps ?? []);
          _brewNotesController.text = recipe.description ?? '';
        }

        _loaded = true;
      });

      // Load equipment names if IDs are set.
      _loadEquipmentNames(recipe);
    } catch (_) {
      // Fall through — user can fill in manually.
    }
  }

  Future<void> _loadEquipmentNames(Recipe recipe) async {
    if (recipe.grinderId != null) {
      try {
        final eq = await ref
            .read(equipmentDetailProvider(recipe.grinderId!).future);
        if (mounted) setState(() => _selectedGrinder = eq);
      } catch (_) {}
    }
    if (recipe.brewerId != null) {
      try {
        final eq = await ref
            .read(equipmentDetailProvider(recipe.brewerId!).future);
        if (mounted) {
          setState(() {
            if (_category == BrewMethodCategory.espresso) {
              _selectedMachine = eq;
            } else {
              _selectedBrewer = eq;
            }
          });
        }
      } catch (_) {}
    }
    if (recipe.coffeeId != null) {
      try {
        final cwr = await ref
            .read(coffeeDetailProvider(recipe.coffeeId!).future);
        if (mounted) {
          setState(() {
            _selectedCoffeeId = cwr.coffee.id;
            _selectedCoffeeName = cwr.coffee.name;
          });
        }
      } catch (_) {}
    }
  }

  // ── Coffee search ────────────────────────────────────────────────────────

  void _onCoffeeSearchChanged(String query) {
    _coffeeSearchDebounce?.cancel();
    _coffeeSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _coffeeSearchQuery = query.trim());
    });
  }

  void _selectCoffee(CoffeeWithRoaster cwr) {
    setState(() {
      _selectedCoffeeId = cwr.coffee.id;
      _selectedCoffeeName = cwr.coffee.name;
      _coffeeSearchController.clear();
      _coffeeSearchQuery = '';
    });
  }

  void _clearCoffee() {
    setState(() {
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
    });
  }

  // ── Equipment pickers ──────────────────────────────────────────────────

  Future<void> _pickGrinder() async {
    final eq = await showEquipmentPicker(
      context,
      equipmentType: 'grinder',
      title: 'Select Grinder',
    );
    if (eq != null && mounted) setState(() => _selectedGrinder = eq);
  }

  Future<void> _pickMachine() async {
    final eq = await showEquipmentPicker(
      context,
      equipmentType: 'brewer',
      title: 'Select Machine',
    );
    if (eq != null && mounted) setState(() => _selectedMachine = eq);
  }

  Future<void> _pickBrewer() async {
    final eq = await showEquipmentPicker(
      context,
      equipmentType: 'brewer',
      title: 'Select Brewer',
    );
    if (eq != null && mounted) setState(() => _selectedBrewer = eq);
  }

  // ── Submit ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final isEspresso = _category == BrewMethodCategory.espresso;

    final fields = <String, dynamic>{
      'title': _titleController.text.trim(),
      'brew_method': _brewMethod,
      if (_selectedCoffeeId != null) 'coffee_id': _selectedCoffeeId,
      if (_selectedGrinder != null) 'grinder_id': _selectedGrinder!.id,
      if (_grinderSettingController.text.trim().isNotEmpty)
        'grinder_setting': _grinderSettingController.text.trim(),
      if (_doseController.text.trim().isNotEmpty)
        'dose_grams': double.tryParse(_doseController.text.trim()),
      if (_ratioController.text.trim().isNotEmpty)
        'ratio': _ratioController.text.trim(),
    };

    if (isEspresso) {
      if (_selectedMachine != null) fields['brewer_id'] = _selectedMachine!.id;
      if (_distributionMethod != null) {
        fields['distribution_method'] = _distributionMethod;
      }
      if (_tampPressureController.text.trim().isNotEmpty) {
        fields['tamp_pressure_kg'] =
            double.tryParse(_tampPressureController.text.trim());
      }
      if (_brewTempController.text.trim().isNotEmpty) {
        fields['water_temp_c'] =
            double.tryParse(_brewTempController.text.trim());
      }
      if (_preInfusionController.text.trim().isNotEmpty) {
        fields['pre_infusion_sec'] =
            int.tryParse(_preInfusionController.text.trim());
      }
      if (_maxPressureController.text.trim().isNotEmpty) {
        fields['max_pressure_bar'] =
            double.tryParse(_maxPressureController.text.trim());
      }
      if (_yieldController.text.trim().isNotEmpty) {
        fields['yield_grams'] =
            double.tryParse(_yieldController.text.trim());
      }
      if (_shotDurationController.text.trim().isNotEmpty) {
        fields['brew_time_sec'] =
            int.tryParse(_shotDurationController.text.trim());
      }
      if (_shotNotesController.text.trim().isNotEmpty) {
        fields['description'] = _shotNotesController.text.trim();
      }
      if (_milkNotesController.text.trim().isNotEmpty) {
        fields['milk_notes'] = _milkNotesController.text.trim();
      }
    } else {
      if (_selectedBrewer != null) fields['brewer_id'] = _selectedBrewer!.id;
      if (_manualBrewTempController.text.trim().isNotEmpty) {
        fields['water_temp_c'] =
            double.tryParse(_manualBrewTempController.text.trim());
      }
      if (_waterAmountController.text.trim().isNotEmpty) {
        fields['water_ml'] =
            double.tryParse(_waterAmountController.text.trim());
      }
      if (_totalBrewTimeController.text.trim().isNotEmpty) {
        fields['brew_time_sec'] =
            int.tryParse(_totalBrewTimeController.text.trim());
      }
      if (_steps.isNotEmpty) {
        fields['steps'] = _steps.map((s) => s.toJson()).toList();
      }
      if (_brewNotesController.text.trim().isNotEmpty) {
        fields['description'] = _brewNotesController.text.trim();
      }
    }

    if (_isFork) {
      fields['forked_from'] = widget.forkedFromId;
    }

    try {
      final notifier = ref.read(recipeProvider.notifier);
      if (_isEdit) {
        await notifier.updateRecipe(widget.recipeId!, fields);
      } else {
        await notifier.createRecipe(fields);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Recipe updated!' : 'Recipe created!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(recipeProvider.notifier).reset();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(recipeProvider);
    final isSubmitting =
        submissionState.status == RecipeSubmissionStatus.submitting;

    // Wait for load in edit/fork mode.
    if ((_isEdit || _isFork) && !_loaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Recipe' : 'New Recipe'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Recipe' : 'New Recipe'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // ── 1. Title ─────────────────────────────────────────────
            _buildSectionHeader('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g., Morning Pour-Over',
              ),
              onChanged: (_) => setState(() {}),
            ),

            // ── 2. Brew Method ───────────────────────────────────────
            _buildSectionHeader('Brew Method'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: brewMethods.map((method) {
                return ChoiceChip(
                  label: Text(method),
                  selected: _brewMethod == method,
                  onSelected: (selected) {
                    setState(() => _brewMethod = selected ? method : null);
                  },
                );
              }).toList(),
            ),

            // ── 3. Coffee Pairing (optional) ─────────────────────────
            _buildSectionHeader('Coffee (optional)'),
            const SizedBox(height: 8),
            _buildCoffeeSection(),

            // ── 4. Grinder ───────────────────────────────────────────
            _buildSectionHeader('Grinder'),
            const SizedBox(height: 8),
            _buildEquipmentField(
              selected: _selectedGrinder,
              placeholder: 'Select Grinder',
              onPick: _pickGrinder,
              onClear: () => setState(() => _selectedGrinder = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _grinderSettingController,
              decoration: const InputDecoration(
                hintText: 'Grinder setting (e.g., 18 clicks)',
              ),
            ),

            // ── 5. Dose ──────────────────────────────────────────────
            _buildSectionHeader('Dose'),
            const SizedBox(height: 8),
            TextField(
              controller: _doseController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Grams',
                suffixText: 'g',
              ),
            ),

            // ── 6. Ratio ─────────────────────────────────────────────
            _buildSectionHeader('Ratio'),
            const SizedBox(height: 8),
            TextField(
              controller: _ratioController,
              decoration: const InputDecoration(
                hintText: 'e.g., 1:16',
              ),
            ),

            // ── Branching sections ───────────────────────────────────
            AnimatedSize(
              duration: kTransitionDuration,
              curve: kTransitionCurve,
              alignment: Alignment.topCenter,
              child: _brewMethod == null
                  ? const SizedBox.shrink()
                  : _category == BrewMethodCategory.espresso
                      ? _buildEspressoFields()
                      : _buildManualFields(),
            ),

            // ── Submit ───────────────────────────────────────────────
            const SizedBox(height: 32),
            _buildSubmitButton(isSubmitting),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(title, style: AppTextStyles.titleMedium),
    );
  }

  // ── Coffee Section ─────────────────────────────────────────────────────

  Widget _buildCoffeeSection() {
    if (_selectedCoffeeId != null) {
      return AnimatedContainer(
        duration: kTransitionDuration,
        curve: kTransitionCurve,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.coffee, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedCoffeeName ?? _selectedCoffeeId!,
                style: AppTextStyles.titleSmall,
              ),
            ),
            TextButton(
              onPressed: _clearCoffee,
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _coffeeSearchController,
          onChanged: _onCoffeeSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search for a coffee...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (_coffeeSearchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildCoffeeSearchResults(),
        ],
      ],
    );
  }

  Widget _buildCoffeeSearchResults() {
    final searchAsync = ref.watch(coffeeSearchProvider(_coffeeSearchQuery));

    return searchAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Error searching: $error',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No coffees found for "$_coffeeSearchQuery"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                title:
                    Text(item.coffee.name, style: AppTextStyles.titleSmall),
                subtitle: item.roaster != null
                    ? Text(
                        item.roaster!.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
                onTap: () => _selectCoffee(item),
              );
            },
          ),
        );
      },
    );
  }

  // ── Equipment Field ────────────────────────────────────────────────────

  Widget _buildEquipmentField({
    required EquipmentCatalog? selected,
    required String placeholder,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    if (selected != null) {
      return AnimatedContainer(
        duration: kTransitionDuration,
        curve: kTransitionCurve,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.build_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${selected.brand} · ${selected.model}',
                style: AppTextStyles.titleSmall,
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.build_outlined, size: 18),
        label: Text(placeholder),
      ),
    );
  }

  // ── Espresso Branch ────────────────────────────────────────────────────

  Widget _buildEspressoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Machine
        _buildSectionHeader('Machine'),
        const SizedBox(height: 8),
        _buildEquipmentField(
          selected: _selectedMachine,
          placeholder: 'Select Machine',
          onPick: _pickMachine,
          onClear: () => setState(() => _selectedMachine = null),
        ),

        // Distribution Method
        _buildSectionHeader('Distribution Method'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _distributionMethods.map((method) {
            return ChoiceChip(
              label: Text(method),
              selected: _distributionMethod == method,
              onSelected: (selected) {
                setState(
                    () => _distributionMethod = selected ? method : null);
              },
            );
          }).toList(),
        ),

        // Tamp Pressure
        _buildSectionHeader('Tamp Pressure'),
        const SizedBox(height: 8),
        TextField(
          controller: _tampPressureController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Pressure',
            suffixText: 'kg',
          ),
        ),

        // Brew Temperature
        _buildSectionHeader('Brew Temperature'),
        const SizedBox(height: 8),
        TextField(
          controller: _brewTempController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Temperature',
            suffixText: '°C',
          ),
        ),

        // Pre-Infusion Time
        _buildSectionHeader('Pre-Infusion Time'),
        const SizedBox(height: 8),
        TextField(
          controller: _preInfusionController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Duration',
            suffixText: 'sec',
          ),
        ),

        // Max Pressure
        _buildSectionHeader('Max Pressure'),
        const SizedBox(height: 8),
        TextField(
          controller: _maxPressureController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Pressure',
            suffixText: 'bar',
          ),
        ),

        // Yield
        _buildSectionHeader('Yield'),
        const SizedBox(height: 8),
        TextField(
          controller: _yieldController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Output weight',
            suffixText: 'g',
          ),
        ),

        // Shot Duration
        _buildSectionHeader('Shot Duration'),
        const SizedBox(height: 8),
        TextField(
          controller: _shotDurationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Duration',
            suffixText: 'sec',
          ),
        ),

        // Shot Notes
        _buildSectionHeader('Shot Notes'),
        const SizedBox(height: 8),
        TextField(
          controller: _shotNotesController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Describe the shot...',
            alignLabelWithHint: true,
          ),
        ),

        // Milk Notes
        _buildSectionHeader('Milk Notes'),
        const SizedBox(height: 8),
        TextField(
          controller: _milkNotesController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Milk type, steaming notes, latte art...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ── Manual Brew Branch ─────────────────────────────────────────────────

  Widget _buildManualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brewer
        _buildSectionHeader('Brewer'),
        const SizedBox(height: 8),
        _buildEquipmentField(
          selected: _selectedBrewer,
          placeholder: 'Select Brewer',
          onPick: _pickBrewer,
          onClear: () => setState(() => _selectedBrewer = null),
        ),

        // Brew Temperature
        _buildSectionHeader('Brew Temperature'),
        const SizedBox(height: 8),
        TextField(
          controller: _manualBrewTempController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Temperature',
            suffixText: '°C',
          ),
        ),

        // Water Amount
        _buildSectionHeader('Water Amount'),
        const SizedBox(height: 8),
        TextField(
          controller: _waterAmountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Total water',
            suffixText: 'ml',
          ),
        ),

        // Total Brew Time
        _buildSectionHeader('Total Brew Time'),
        const SizedBox(height: 8),
        TextField(
          controller: _totalBrewTimeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Total time',
            suffixText: 'sec',
          ),
        ),

        // Steps
        _buildSectionHeader('Steps'),
        const SizedBox(height: 8),
        StepsEditor(
          steps: _steps,
          onChanged: (updated) => setState(() => _steps = updated),
        ),

        // Brew Notes
        _buildSectionHeader('Brew Notes'),
        const SizedBox(height: 8),
        TextField(
          controller: _brewNotesController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Additional notes about the brew...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ── Submit Button ──────────────────────────────────────────────────────

  Widget _buildSubmitButton(bool isSubmitting) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _canSubmit && !isSubmitting ? _submit : null,
        child: isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : Text(_isEdit ? 'Save Changes' : 'Create Recipe'),
      ),
    );
  }
}
