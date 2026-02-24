import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/coffee_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe_card.dart';

/// Full detail screen for a single coffee.
///
/// Shows the coffee name, roaster, rating, origin/process/variety info,
/// description, recent check-ins, and a prominent "Check in this coffee"
/// button.
class CoffeeDetailScreen extends ConsumerWidget {
  const CoffeeDetailScreen({super.key, required this.coffeeId});

  /// The unique identifier of the coffee to display.
  final String coffeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coffeeAsync = ref.watch(coffeeDetailProvider(coffeeId));

    return coffeeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Could not load coffee',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(coffeeDetailProvider(coffeeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (coffeeWithRoaster) => _CoffeeDetailBody(
        coffeeWithRoaster: coffeeWithRoaster,
        coffeeId: coffeeId,
      ),
    );
  }
}

class _CoffeeDetailBody extends ConsumerWidget {
  const _CoffeeDetailBody({
    required this.coffeeWithRoaster,
    required this.coffeeId,
  });

  final CoffeeWithRoaster coffeeWithRoaster;
  final String coffeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coffee = coffeeWithRoaster.coffee;
    final roaster = coffeeWithRoaster.roaster;
    final checkInsAsync = ref.watch(coffeeCheckInsProvider(coffeeId));
    final recipesAsync = ref.watch(recipesByCoffeeProvider(coffeeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          coffee.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coffee.name,
                  style: AppTextStyles.headlineMedium,
                ),
                if (roaster != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.push('/roaster/${roaster.id}'),
                    child: Text(
                      roaster.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Rating Display ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LargeRatingDisplay(
              rating: coffee.avgRating,
              checkInCount: coffee.checkInCount,
            ),
          ),

          const SizedBox(height: 24),

          // ── Info Section ────────────────────────────────────────────
          if (_hasInfoFields(coffee))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoSection(coffee: coffee),
            ),

          // ── Description ─────────────────────────────────────────────
          if (coffee.description != null && coffee.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    coffee.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // ── Recent Check-ins ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recent Check-ins', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 12),
          checkInsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load check-ins',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (checkIns) {
              if (checkIns.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No check-ins yet -- be the first!',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: checkIns.map((checkIn) {
                  return _CheckInTile(checkIn: checkIn);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // ── Recipes ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recipes', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 12),
          recipesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load recipes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (recipes) {
              if (recipes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recipes for this coffee yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: recipes
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RecipeCard(item: item),
                          ))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),

      // ── Bottom Button ───────────────────────────────────────────────
      bottomSheet: Container(
        color: AppColors.background,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/check-in?coffeeId=$coffeeId');
            },
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Check in this coffee'),
          ),
        ),
      ),
    );
  }

  bool _hasInfoFields(coffee) {
    return (coffee.origin != null && coffee.origin!.isNotEmpty) ||
        (coffee.process != null && coffee.process!.isNotEmpty) ||
        (coffee.variety != null && coffee.variety!.isNotEmpty) ||
        (coffee.tastingNotes != null && coffee.tastingNotes!.isNotEmpty);
  }
}

// ── Large Rating Display ────────────────────────────────────────────────────

class _LargeRatingDisplay extends StatelessWidget {
  const _LargeRatingDisplay({this.rating, this.checkInCount});

  final double? rating;
  final int? checkInCount;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No ratings yet',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rating!.toStringAsFixed(1),
            style: AppTextStyles.ratingLarge,
          ),
          Text(
            '/5',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          _StarRow(rating: rating!, size: 20),
          if (checkInCount != null && checkInCount! > 0) ...[
            const SizedBox(width: 12),
            Text(
              '($checkInCount)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Star Row ────────────────────────────────────────────────────────────────

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

// ── Info Section ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.coffee});

  final dynamic coffee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (coffee.origin != null && coffee.origin!.isNotEmpty)
            _InfoRow(label: 'Origin', value: coffee.origin!),
          if (coffee.process != null && coffee.process!.isNotEmpty)
            _InfoRow(label: 'Process', value: coffee.process!),
          if (coffee.variety != null && coffee.variety!.isNotEmpty)
            _InfoRow(label: 'Variety', value: coffee.variety!),
          if (coffee.tastingNotes != null && coffee.tastingNotes!.isNotEmpty)
            _InfoRow(label: 'Tasting Notes', value: coffee.tastingNotes!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check-in Tile ───────────────────────────────────────────────────────────

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({required this.checkIn});

  final CheckInWithProfile checkIn;

  @override
  Widget build(BuildContext context) {
    final displayName = checkIn.displayName ?? checkIn.username ?? 'Anonymous';
    final timeAgo = timeago.format(checkIn.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar, name, rating, time
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface,
                  backgroundImage: checkIn.avatarUrl != null
                      ? NetworkImage(checkIn.avatarUrl!)
                      : null,
                  child: checkIn.avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 18,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),

                // Name
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.ratingFilled,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      checkIn.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ],
            ),

            // Notes preview
            if (checkIn.notes != null && checkIn.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                checkIn.notes!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Brew method + time
            const SizedBox(height: 6),
            Row(
              children: [
                if (checkIn.brewMethod != null &&
                    checkIn.brewMethod!.isNotEmpty) ...[
                  Icon(
                    Icons.coffee_maker_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    checkIn.brewMethod!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  timeAgo,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
