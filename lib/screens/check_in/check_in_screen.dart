import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/roaster.dart';
import '../../models/venue.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/coffee_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/add_coffee_bottom_sheet.dart';
import '../../widgets/photo_picker_tile.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _preparations = [
  'Espresso',
  'Drip',
  'Manual-Brew / Pour-Over',
  'Macchiato',
  'Cortado',
  'Cappuccino',
  'Latte',
  'Specialty Drink / Other',
];

const _flavorTagOptions = [
  'Chocolate',
  'Nutty',
  'Fruity',
  'Citrus',
  'Floral',
  'Berry',
  'Caramel',
  'Spicy',
  'Earthy',
  'Bright',
  'Smooth',
  'Bold',
  'Sweet',
  'Crisp',
];

// ── Check-in Screen ──────────────────────────────────────────────────────────

/// Roaster-first check-in flow.
///
/// Accepts an optional [coffeeId] to pre-select a coffee (e.g. from the
/// coffee detail screen's "Check in this coffee" button).
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, this.coffeeId});

  final String? coffeeId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  // ── Roaster state ─────────────────────────────────────────────────────────
  Roaster? _selectedRoaster;
  bool _roasterSkipped = false;
  String _roasterSearchQuery = '';
  Timer? _roasterSearchDebounce;
  final _roasterSearchController = TextEditingController();

  // ── Coffee state ──────────────────────────────────────────────────────────
  String? _selectedCoffeeId;
  String? _selectedCoffeeName;
  String? _selectedRoasterName;
  String _coffeeSearchQuery = '';
  Timer? _coffeeSearchDebounce;
  final _coffeeSearchController = TextEditingController();

  // ── Venue state ───────────────────────────────────────────────────────────
  String? _venueType;
  Venue? _selectedVenue;
  String _venueSearchQuery = '';
  Timer? _venueSearchDebounce;
  final _venueSearchController = TextEditingController();

  // ── Preparation state ─────────────────────────────────────────────────────
  String? _preparation;
  final _specialtyDrinkController = TextEditingController();

  // ── Photo state ────────────────────────────────────────────────────────────
  String? _photoUrl;

  // ── Rating / Tags / Notes ─────────────────────────────────────────────────
  double _rating = 0;
  final Set<String> _flavorTags = {};
  final _notesController = TextEditingController();

  bool get _canSubmit => _selectedCoffeeId != null && _rating > 0;

  /// Whether the roaster step is complete (selected or skipped).
  bool get _roasterDone => _selectedRoaster != null || _roasterSkipped;

  /// Whether the coffee step is complete.
  bool get _coffeeDone => _selectedCoffeeId != null;

  @override
  void initState() {
    super.initState();
    if (widget.coffeeId != null) {
      _loadPreselectedCoffee(widget.coffeeId!);
    }
  }

  @override
  void dispose() {
    _roasterSearchController.dispose();
    _coffeeSearchController.dispose();
    _venueSearchController.dispose();
    _specialtyDrinkController.dispose();
    _notesController.dispose();
    _roasterSearchDebounce?.cancel();
    _coffeeSearchDebounce?.cancel();
    _venueSearchDebounce?.cancel();
    super.dispose();
  }

  // ── Pre-selection ─────────────────────────────────────────────────────────

  Future<void> _loadPreselectedCoffee(String coffeeId) async {
    try {
      final cwr = await ref.read(coffeeDetailProvider(coffeeId).future);
      if (mounted) {
        setState(() {
          _selectedCoffeeId = cwr.coffee.id;
          _selectedCoffeeName = cwr.coffee.name;
          _selectedRoasterName = cwr.roaster?.name;
          if (cwr.roaster != null) {
            _selectedRoaster = cwr.roaster;
          } else {
            _roasterSkipped = true;
          }
        });
      }
    } catch (_) {
      // Fall through — user can search manually.
    }
  }

  // ── Debounced search helpers ──────────────────────────────────────────────

  void _onRoasterSearchChanged(String query) {
    _roasterSearchDebounce?.cancel();
    _roasterSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _roasterSearchQuery = query.trim());
    });
  }

  void _onCoffeeSearchChanged(String query) {
    _coffeeSearchDebounce?.cancel();
    _coffeeSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _coffeeSearchQuery = query.trim());
    });
  }

  void _onVenueSearchChanged(String query) {
    _venueSearchDebounce?.cancel();
    _venueSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _venueSearchQuery = query.trim());
    });
  }

  // ── Selection actions ─────────────────────────────────────────────────────

  void _selectRoaster(Roaster roaster) {
    setState(() {
      _selectedRoaster = roaster;
      _roasterSkipped = false;
      _roasterSearchController.clear();
      _roasterSearchQuery = '';
      // Clear coffee selection since roaster changed.
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
      _selectedRoasterName = roaster.name;
      _coffeeSearchController.clear();
      _coffeeSearchQuery = '';
    });
  }

  void _skipRoaster() {
    setState(() {
      _roasterSkipped = true;
      _selectedRoaster = null;
      _roasterSearchController.clear();
      _roasterSearchQuery = '';
      // Clear coffee selection.
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
      _selectedRoasterName = null;
      _coffeeSearchController.clear();
      _coffeeSearchQuery = '';
    });
  }

  void _changeRoaster() {
    setState(() {
      _selectedRoaster = null;
      _roasterSkipped = false;
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
      _selectedRoasterName = null;
    });
  }

  void _selectCoffee(CoffeeWithRoaster cwr) {
    setState(() {
      _selectedCoffeeId = cwr.coffee.id;
      _selectedCoffeeName = cwr.coffee.name;
      _selectedRoasterName = cwr.roaster?.name;
      _coffeeSearchController.clear();
      _coffeeSearchQuery = '';
    });
  }

  void _changeCoffee() {
    setState(() {
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
      // Keep roaster selection intact.
    });
  }

  void _selectVenue(Venue venue) {
    setState(() {
      _selectedVenue = venue;
      _venueSearchController.clear();
      _venueSearchQuery = '';
    });
  }

  // ── Inline add coffee ─────────────────────────────────────────────────────

  Future<void> _openAddCoffeeSheet() async {
    final result = await showAddCoffeeBottomSheet(
      context,
      roasterId: _selectedRoaster?.id,
      roasterName: _selectedRoaster?.name,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedCoffeeId = result.id;
        _selectedCoffeeName = result.name;
        _coffeeSearchController.clear();
        _coffeeSearchQuery = '';
      });
      // Invalidate so lists pick up the new coffee.
      ref.invalidate(coffeeListProvider);
      ref.invalidate(recentCoffeesProvider);
      if (_selectedRoaster != null) {
        ref.invalidate(coffeesByRoasterProvider(_selectedRoaster!.id));
      }
    }
  }

  // ── Inline add venue ──────────────────────────────────────────────────────

  Future<void> _addNewVenue() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Venue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Venue Name *',
                hintText: 'e.g., Blue Bottle Coffee',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                hintText: 'e.g., 123 Main St',
              ),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty && mounted) {
      try {
        final venue = await addVenue(
          name: nameController.text,
          address: addressController.text.isNotEmpty
              ? addressController.text
              : null,
        );
        if (mounted) {
          setState(() {
            _selectedVenue = venue;
            _venueSearchController.clear();
            _venueSearchQuery = '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add venue: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    nameController.dispose();
    addressController.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;

    try {
      await ref.read(checkInProvider.notifier).submitCheckIn(
            coffeeId: _selectedCoffeeId!,
            rating: _rating,
            notes: _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
            flavorTags: _flavorTags.isNotEmpty ? _flavorTags.toList() : null,
            preparation: _preparation,
            specialtyDrink: _preparation == 'Specialty Drink / Other'
                ? _specialtyDrinkController.text
                : null,
            venueType: _venueType,
            venueId: _selectedVenue?.id,
            photoUrl: _photoUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in saved!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(checkInProvider.notifier).reset();
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save check-in: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(checkInProvider);
    final isSubmitting =
        submissionState.status == CheckInSubmissionStatus.submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('New Check-in')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // ── 1. Roaster ────────────────────────────────────────────────
            _buildSectionHeader('Roaster'),
            const SizedBox(height: 8),
            if (!_roasterDone) ...[
              _buildRoasterSearch(),
            ] else ...[
              _buildSelectedRoasterCard(),
            ],

            // ── 2. Coffee (only after roaster step done) ──────────────────
            AnimatedSize(
              duration: kTransitionDuration,
              curve: kTransitionCurve,
              alignment: Alignment.topCenter,
              child: _roasterDone
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Coffee'),
                        const SizedBox(height: 8),
                        if (!_coffeeDone)
                          _buildCoffeeSearch()
                        else
                          _buildSelectedCoffeeCard(),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Remaining fields (only after coffee selected) ─────────────
            AnimatedSize(
              duration: kTransitionDuration,
              curve: kTransitionCurve,
              alignment: Alignment.topCenter,
              child: !_coffeeDone
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // ── 3. Venue Type ───────────────────────────────────────────
              _buildSectionHeader('Where are you?'),
              const SizedBox(height: 8),
              _buildVenueTypeChips(),

              // ── 4. Venue (cafe only) ────────────────────────────────────
              if (_venueType == 'cafe') ...[
                const SizedBox(height: 8),
                _buildVenueSearch(),
              ],

              // ── 5. Preparation ──────────────────────────────────────────
              _buildSectionHeader('Preparation'),
              const SizedBox(height: 8),
              _buildPreparationChips(),

              // ── 6. Specialty Drink ──────────────────────────────────────
              if (_preparation == 'Specialty Drink / Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _specialtyDrinkController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'What drink? e.g., Oat Milk Mocha',
                  ),
                ),
              ],

              // ── 7. Flavor Tags ──────────────────────────────────────────
              _buildSectionHeader('Flavor Tags'),
              const SizedBox(height: 8),
              _buildFlavorTagChips(),

              // ── 8. Rating ───────────────────────────────────────────────
              _buildSectionHeader('Rating'),
              const SizedBox(height: 8),
              _buildRatingSection(),

              // ── 9. Notes ────────────────────────────────────────────────
              _buildSectionHeader('Notes'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tell us about your experience',
                  alignLabelWithHint: true,
                ),
              ),

              // ── 10. Photo ───────────────────────────────────────────────
              _buildSectionHeader('Photo'),
              const SizedBox(height: 8),
              PhotoPickerTile(
                folder: 'check-ins',
                imageUrl: _photoUrl,
                onUploaded: (url) => setState(() => _photoUrl = url),
              ),

              // ── Submit ──────────────────────────────────────────────────
              const SizedBox(height: 32),
              _buildSubmitButton(isSubmitting),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(title, style: AppTextStyles.titleMedium),
    );
  }

  // ── Roaster Widgets ───────────────────────────────────────────────────────

  Widget _buildRoasterSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _roasterSearchController,
          onChanged: _onRoasterSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search for a roaster...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (_roasterSearchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRoasterSearchResults(),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _skipRoaster,
            child: Text(
              "Skip / I don't know the roaster",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoasterSearchResults() {
    final searchAsync = ref.watch(roasterSearchProvider(_roasterSearchQuery));

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
              'No roasters found for "$_roasterSearchQuery"',
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
              final roaster = results[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                title: Text(roaster.name, style: AppTextStyles.titleSmall),
                subtitle: roaster.location != null
                    ? Text(
                        roaster.location!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
                onTap: () => _selectRoaster(roaster),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedRoasterCard() {
    final name = _roasterSkipped ? 'Unknown roaster' : _selectedRoaster!.name;
    return AnimatedContainer(
      duration: kTransitionDuration,
      curve: kTransitionCurve,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.storefront,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: _roasterSkipped
                  ? AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    )
                  : AppTextStyles.titleSmall,
            ),
          ),
          TextButton(
            onPressed: _changeRoaster,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // ── Coffee Widgets ────────────────────────────────────────────────────────

  Widget _buildCoffeeSearch() {
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
        const SizedBox(height: 8),
        // If roaster selected: show their coffees, else show search results.
        if (_selectedRoaster != null && _coffeeSearchQuery.isEmpty)
          _buildRoasterCoffeeList()
        else if (_coffeeSearchQuery.isNotEmpty)
          _buildCoffeeSearchResults(),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openAddCoffeeSheet,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Coffee not listed? Add it',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoasterCoffeeList() {
    final coffeesAsync =
        ref.watch(coffeesByRoasterProvider(_selectedRoaster!.id));

    return coffeesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Error loading coffees: $error',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No coffees found for this roaster',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return _buildCoffeeResultsList(results);
      },
    );
  }

  Widget _buildCoffeeSearchResults() {
    // If roaster selected, filter by roaster's coffees via the search query;
    // otherwise search all coffees.
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

        return _buildCoffeeResultsList(results);
      },
    );
  }

  Widget _buildCoffeeResultsList(List<CoffeeWithRoaster> results) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
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
            title: Text(item.coffee.name, style: AppTextStyles.titleSmall),
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
  }

  Widget _buildSelectedCoffeeCard() {
    return AnimatedContainer(
      duration: kTransitionDuration,
      curve: kTransitionCurve,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.coffee,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedCoffeeName ?? '', style: AppTextStyles.titleSmall),
                if (_selectedRoasterName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedRoasterName!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: _changeCoffee,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // ── Venue Type Chips ──────────────────────────────────────────────────────

  Widget _buildVenueTypeChips() {
    const types = ['home', 'cafe', 'other'];
    const labels = {'home': 'Home', 'cafe': 'Cafe', 'other': 'Other'};

    return Wrap(
      spacing: 8,
      children: types.map((type) {
        final isSelected = _venueType == type;
        return ChoiceChip(
          label: Text(labels[type]!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _venueType = selected ? type : null;
              if (_venueType != 'cafe') {
                _selectedVenue = null;
                _venueSearchController.clear();
                _venueSearchQuery = '';
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Venue Search ──────────────────────────────────────────────────────────

  Widget _buildVenueSearch() {
    if (_selectedVenue != null) {
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
            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_selectedVenue!.name, style: AppTextStyles.titleSmall),
            ),
            TextButton(
              onPressed: () => setState(() {
                _selectedVenue = null;
                _venueSearchController.clear();
                _venueSearchQuery = '';
              }),
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _venueSearchController,
          onChanged: _onVenueSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search for a cafe...',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        if (_venueSearchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildVenueSearchResults(),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addNewVenue,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Add new venue',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueSearchResults() {
    final searchAsync = ref.watch(venueSearchProvider(_venueSearchQuery));

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
              'No venues found for "$_venueSearchQuery"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final venue = results[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: const Icon(Icons.location_on, size: 20),
                title: Text(venue.name, style: AppTextStyles.titleSmall),
                subtitle: venue.address != null
                    ? Text(
                        venue.address!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                onTap: () => _selectVenue(venue),
              );
            },
          ),
        );
      },
    );
  }

  // ── Preparation Chips ─────────────────────────────────────────────────────

  Widget _buildPreparationChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _preparations.map((prep) {
        final isSelected = _preparation == prep;
        return ChoiceChip(
          label: Text(prep),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _preparation = selected ? prep : null;
              if (_preparation != 'Specialty Drink / Other') {
                _specialtyDrinkController.clear();
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Flavor Tag Chips ──────────────────────────────────────────────────────

  Widget _buildFlavorTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _flavorTagOptions.map((tag) {
        final isSelected = _flavorTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _flavorTags.add(tag);
              } else {
                _flavorTags.remove(tag);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Rating Section ────────────────────────────────────────────────────────

  Widget _buildRatingSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RatingBar.builder(
          initialRating: _rating,
          minRating: 0.5,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 40,
          unratedColor: AppColors.ratingEmpty,
          itemBuilder: (context, _) => const Icon(
            Icons.star_rounded,
            color: AppColors.ratingFilled,
          ),
          onRatingUpdate: (value) => setState(() => _rating = value),
        ),
        const SizedBox(width: 16),
        Text(
          _rating > 0 ? _rating.toStringAsFixed(1) : '-',
          style: AppTextStyles.ratingLarge,
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────

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
            : const Text('Check In'),
      ),
    );
  }
}
