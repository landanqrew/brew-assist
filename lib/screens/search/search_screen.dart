import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/coffee_provider.dart';
import '../../providers/social_provider.dart';

/// The discovery / search tab.
///
/// Two tabs — "Coffees" (original behavior) and "Users" (new).
/// Shared search bar at the top with debounced queries.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final TabController _tabController;

  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Coffees'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.primaryDark, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // ── Tab Content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Coffees tab
                _query.isEmpty
                    ? _RecentCoffeesView()
                    : _CoffeeSearchResultsView(query: _query),

                // Users tab
                _query.isEmpty
                    ? _EmptyUserSearchView()
                    : _UserSearchResultsView(query: _query),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coffee/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Coffee'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COFFEES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentCoffeesView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentCoffeesProvider);

    return recentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Could not load coffees',
        onRetry: () => ref.invalidate(recentCoffeesProvider),
      ),
      data: (coffees) {
        if (coffees.isEmpty) return _EmptyDiscoveryView();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: coffees.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Text('Recently Added',
                    style: AppTextStyles.headlineSmall),
              );
            }
            return _CoffeeCard(coffeeWithRoaster: coffees[index - 1]);
          },
        );
      },
    );
  }
}

class _CoffeeSearchResultsView extends ConsumerWidget {
  const _CoffeeSearchResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(coffeeSearchProvider(query));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Search failed',
        onRetry: () => ref.invalidate(coffeeSearchProvider(query)),
      ),
      data: (coffees) {
        if (coffees.isEmpty) return _NoResultsView(query: query);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: coffees.length,
          itemBuilder: (context, index) {
            return _CoffeeCard(coffeeWithRoaster: coffees[index]);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyUserSearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Search for coffee lovers',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Find other users by name or username.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchResultsView extends ConsumerWidget {
  const _UserSearchResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(userSearchProvider(query));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Search failed',
        onRetry: () => ref.invalidate(userSearchProvider(query)),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found for "$query"',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surface,
                backgroundImage: user.avatarUrl != null &&
                        user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? const Icon(Icons.person,
                        size: 20, color: AppColors.textSecondary)
                    : null,
              ),
              title: Text(
                user.displayName ?? user.username,
                style: AppTextStyles.titleSmall,
              ),
              subtitle: Text(
                '@${user.username}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              onTap: () => context.push('/user/${user.id}'),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS (unchanged from Phase 1)
// ═══════════════════════════════════════════════════════════════════════════════

class _CoffeeCard extends StatelessWidget {
  const _CoffeeCard({required this.coffeeWithRoaster});

  final CoffeeWithRoaster coffeeWithRoaster;

  @override
  Widget build(BuildContext context) {
    final coffee = coffeeWithRoaster.coffee;
    final roaster = coffeeWithRoaster.roaster;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: AppColors.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/coffee/${coffee.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coffee.name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (roaster != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          roaster.name,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (coffee.origin != null &&
                          coffee.origin!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _OriginChip(origin: coffee.origin!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _RatingBadge(rating: coffee.avgRating),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.origin});

  final String origin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        origin,
        style:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({this.rating});

  final double? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return Text(
        'No ratings',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rating!.toStringAsFixed(1), style: AppTextStyles.ratingSmall),
            Text('/5',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        _StarRow(rating: rating!, size: 14),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star;
          color = AppColors.ratingFilled;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
          color = AppColors.ratingFilled;
        } else {
          icon = Icons.star_border;
          color = AppColors.ratingEmpty;
        }

        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

class _EmptyDiscoveryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Discover Coffees', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'No coffees have been added yet.\nBe the first to add one!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/coffee/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Coffee'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No coffees found', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'No results for "$query"',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/coffee/add'),
              icon: const Icon(Icons.add),
              label: const Text('Be the first to add it'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
