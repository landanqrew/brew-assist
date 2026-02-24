import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe_card.dart';

/// Browse screen for community recipes with search, brew method filtering,
/// sort options, and a trending section.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String? _selectedBrewMethod;
  String _sortBy = 'newest';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value.trim());
    });
  }

  bool get _isSearching => _searchQuery.isNotEmpty;

  RecipeListParam get _listParam =>
      (brewMethod: _selectedBrewMethod, sortBy: _sortBy);

  @override
  Widget build(BuildContext context) {
    final recipesAsync = _isSearching
        ? ref.watch(recipeSearchProvider(_searchQuery))
        : ref.watch(recipeListProvider(_listParam));

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Brew method filter chips (hidden during search)
          if (!_isSearching) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedBrewMethod == null,
                      onSelected: (_) {
                        setState(() => _selectedBrewMethod = null);
                      },
                    ),
                  ),
                  ...brewMethods.map((method) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(method),
                        selected: _selectedBrewMethod == method,
                        onSelected: (selected) {
                          setState(() => _selectedBrewMethod =
                              selected ? method : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Sort chips
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SortChip(
                    label: 'Newest',
                    icon: Icons.schedule,
                    value: 'newest',
                    selected: _sortBy,
                    onSelected: (v) => setState(() => _sortBy = v),
                  ),
                  _SortChip(
                    label: 'Top Rated',
                    icon: Icons.star_rounded,
                    value: 'topRated',
                    selected: _sortBy,
                    onSelected: (v) => setState(() => _sortBy = v),
                  ),
                  _SortChip(
                    label: 'Most Saved',
                    icon: Icons.bookmark_rounded,
                    value: 'mostSaved',
                    selected: _sortBy,
                    onSelected: (v) => setState(() => _sortBy = v),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Recipe list
          Expanded(
            child: recipesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(isSearch: _isSearching);
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (_isSearching) {
                      ref.invalidate(recipeSearchProvider(_searchQuery));
                    } else {
                      ref.invalidate(recipeListProvider(_listParam));
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount:
                        items.length + (_isSearching ? 0 : 1), // +1 trending
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      // Trending section as first item
                      if (!_isSearching && index == 0) {
                        return const _TrendingSection();
                      }
                      final itemIndex = _isSearching ? index : index - 1;
                      return RecipeCard(item: items[itemIndex]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Something went wrong',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (_isSearching) {
                            ref.invalidate(
                                recipeSearchProvider(_searchQuery));
                          } else {
                            ref.invalidate(recipeListProvider(_listParam));
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recipe/new'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

// ── Sort Chip ────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

// ── Trending Section ─────────────────────────────────────────────────────────

class _TrendingSection extends ConsumerWidget {
  const _TrendingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingRecipesProvider);

    return trendingAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRENDING',
              style: AppTextStyles.kicker.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _TrendingCard(item: items[index]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Trending Card ────────────────────────────────────────────────────────────

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.item});

  final RecipeFeedItem item;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;
    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: AppColors.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating badge
            if (recipe.avgRating != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      recipe.avgRating!.toStringAsFixed(1),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Text(
              recipe.title,
              style: AppTextStyles.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              recipe.brewMethod,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (item.authorDisplayName != null ||
                item.authorUsername != null) ...[
              const SizedBox(height: 2),
              Text(
                item.authorDisplayName ?? item.authorUsername ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No recipes found' : 'No recipes yet',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search term.'
                  : 'Be the first to share a brew recipe!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearch) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/recipe/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create a Recipe'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
