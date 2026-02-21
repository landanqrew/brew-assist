import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/coffee_provider.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _brewMethods = [
  'Espresso',
  'Pour-over',
  'French Press',
  'AeroPress',
  'Cold Brew',
  'Drip',
  'Moka Pot',
  'Other',
];

const _servingStyles = [
  'Black',
  'With Milk',
  'Iced',
  'Latte',
  'Cappuccino',
  'Other',
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

/// The main check-in flow screen. A single scrollable form for logging a
/// coffee experience.
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
  // ── Form state ───────────────────────────────────────────────────────────

  /// The currently selected coffee (id, name, roaster name).
  String? _selectedCoffeeId;
  String? _selectedCoffeeName;
  String? _selectedRoasterName;

  /// Whether the user is searching for a coffee (vs. having one selected).
  bool _isSearching = false;

  /// Search query for the coffee search field.
  String _searchQuery = '';

  /// Timer for debouncing search input.
  Timer? _searchDebounce;

  /// Rating value (0 means unset).
  double _rating = 0;

  /// Selected brew method (single select).
  String? _brewMethod;

  /// Selected serving style (single select).
  String? _servingStyle;

  /// Selected flavor tags (multi-select).
  final Set<String> _flavorTags = {};

  /// Tasting notes controller.
  final _notesController = TextEditingController();

  /// Search field controller.
  final _searchController = TextEditingController();

  /// Whether the form is ready to submit.
  bool get _canSubmit => _selectedCoffeeId != null && _rating > 0;

  @override
  void initState() {
    super.initState();

    // If a coffeeId was passed, pre-load that coffee.
    if (widget.coffeeId != null) {
      _loadPreselectedCoffee(widget.coffeeId!);
    } else {
      _isSearching = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Loads a pre-selected coffee by ID and populates the selection fields.
  Future<void> _loadPreselectedCoffee(String coffeeId) async {
    try {
      final coffeeWithRoaster =
          await ref.read(coffeeDetailProvider(coffeeId).future);
      if (mounted) {
        setState(() {
          _selectedCoffeeId = coffeeWithRoaster.coffee.id;
          _selectedCoffeeName = coffeeWithRoaster.coffee.name;
          _selectedRoasterName = coffeeWithRoaster.roaster?.name;
          _isSearching = false;
        });
      }
    } catch (_) {
      // If loading fails, fall back to search mode.
      if (mounted) {
        setState(() {
          _isSearching = true;
        });
      }
    }
  }

  /// Called when the search query changes; debounces to avoid excessive calls.
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
      }
    });
  }

  /// Selects a coffee from search results.
  void _selectCoffee(CoffeeWithRoaster coffeeWithRoaster) {
    setState(() {
      _selectedCoffeeId = coffeeWithRoaster.coffee.id;
      _selectedCoffeeName = coffeeWithRoaster.coffee.name;
      _selectedRoasterName = coffeeWithRoaster.roaster?.name;
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  /// Clears the current selection and returns to search mode.
  void _changeCoffee() {
    setState(() {
      _selectedCoffeeId = null;
      _selectedCoffeeName = null;
      _selectedRoasterName = null;
      _isSearching = true;
    });
  }

  /// Submits the check-in.
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
            brewMethod: _brewMethod,
            servingStyle: _servingStyle,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in saved!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Reset the provider for next time.
        ref.read(checkInProvider.notifier).reset();

        // Navigate to feed.
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(checkInProvider);
    final isSubmitting =
        submissionState.status == CheckInSubmissionStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Check-in'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // ── Coffee Selection ──────────────────────────────────────────
            _buildSectionHeader('Coffee'),
            const SizedBox(height: 8),
            if (_isSearching) ...[
              _buildCoffeeSearch(),
            ] else ...[
              _buildSelectedCoffeeCard(),
            ],

            // ── Rating ───────────────────────────────────────────────────
            _buildSectionHeader('Rating'),
            const SizedBox(height: 8),
            _buildRatingSection(),

            // ── Brew Method ──────────────────────────────────────────────
            _buildSectionHeader('Brew Method'),
            const SizedBox(height: 8),
            _buildBrewMethodChips(),

            // ── Serving Style ────────────────────────────────────────────
            _buildSectionHeader('Serving Style'),
            const SizedBox(height: 8),
            _buildServingStyleChips(),

            // ── Flavor Tags ──────────────────────────────────────────────
            _buildSectionHeader('Flavor Tags'),
            const SizedBox(height: 8),
            _buildFlavorTagChips(),

            // ── Tasting Notes ────────────────────────────────────────────
            _buildSectionHeader('Tasting Notes'),
            const SizedBox(height: 8),
            _buildNotesField(),

            // ── Submit Button ────────────────────────────────────────────
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
      child: Text(
        title,
        style: AppTextStyles.titleMedium,
      ),
    );
  }

  // ── Coffee Selection Widgets ───────────────────────────────────────────

  Widget _buildCoffeeSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search for a coffee...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(coffeeSearchProvider(_searchQuery));

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
              'No coffees found for "$_searchQuery"',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }

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
                title: Text(
                  item.coffee.name,
                  style: AppTextStyles.titleSmall,
                ),
                subtitle: item.roaster != null
                    ? Text(
                        item.roaster!.name,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
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

  Widget _buildSelectedCoffeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Coffee icon.
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
          // Coffee name & roaster.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCoffeeName ?? '',
                  style: AppTextStyles.titleSmall,
                ),
                if (_selectedRoasterName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedRoasterName!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          // Change button.
          TextButton(
            onPressed: _changeCoffee,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // ── Rating Widget ──────────────────────────────────────────────────────

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
          onRatingUpdate: (value) {
            setState(() {
              _rating = value;
            });
          },
        ),
        const SizedBox(width: 16),
        Text(
          _rating > 0 ? _rating.toStringAsFixed(1) : '-',
          style: AppTextStyles.ratingLarge,
        ),
      ],
    );
  }

  // ── Brew Method Chips ──────────────────────────────────────────────────

  Widget _buildBrewMethodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _brewMethods.map((method) {
          final isSelected = _brewMethod == method;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(method),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _brewMethod = selected ? method : null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Serving Style Chips ────────────────────────────────────────────────

  Widget _buildServingStyleChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _servingStyles.map((style) {
          final isSelected = _servingStyle == style;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _servingStyle = selected ? style : null;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Flavor Tag Chips ───────────────────────────────────────────────────

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

  // ── Notes Field ────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'How did it taste? Any thoughts on the brew?',
        alignLabelWithHint: true,
      ),
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
            : const Text('Check In'),
      ),
    );
  }
}
