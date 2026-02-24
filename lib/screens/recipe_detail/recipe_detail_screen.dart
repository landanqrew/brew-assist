import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/gradient_button.dart';

/// Full detail screen for a single recipe.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return recipeAsync.when(
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
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Could not load recipe',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(recipeDetailProvider(recipeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (recipe) =>
          _RecipeDetailBody(recipe: recipe, recipeId: recipeId),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _RecipeDetailBody extends ConsumerWidget {
  const _RecipeDetailBody({required this.recipe, required this.recipeId});

  final Recipe recipe;
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authProvider).user?.id;
    final isOwner = me == recipe.userId;
    final isEspresso =
        classifyBrewMethod(recipe.brewMethod) == BrewMethodCategory.espresso;
    final profileAsync = ref.watch(userProfileProvider(recipe.userId));
    final isSaved =
        ref.watch(isSavedByMeProvider(recipeId)).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _onMenuAction(context, ref, value, isOwner),
            itemBuilder: (ctx) => [
              if (isOwner)
                const PopupMenuItem(
                    value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'fork', child: Text('Fork')),
              if (isOwner)
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 140),
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),

                // Author row
                profileAsync.when(
                  data: (profile) => GestureDetector(
                    onTap: () =>
                        context.push('/user/${recipe.userId}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surface,
                          backgroundImage: profile.avatarUrl != null &&
                                  profile.avatarUrl!.isNotEmpty
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null ||
                                  profile.avatarUrl!.isEmpty
                              ? const Icon(Icons.person,
                                  size: 16,
                                  color: AppColors.textSecondary)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.displayName ?? profile.username,
                          style: AppTextStyles.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),

                // Brew method chip + time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.brewMethod,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeago.format(recipe.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Rating + Save Count ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RatingSection(
              recipe: recipe,
              recipeId: recipeId,
              isOwner: isOwner,
            ),
          ),

          const SizedBox(height: 24),

          // ── Parameters Card ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ParametersCard(
              recipe: recipe,
              isEspresso: isEspresso,
            ),
          ),

          // ── Steps ──────────────────────────────────────────────
          if (recipe.steps != null && recipe.steps!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StepsSection(steps: recipe.steps!),
            ),
          ],

          // ── Description ────────────────────────────────────────
          if (recipe.description != null &&
              recipe.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Milk Notes (espresso only) ─────────────────────────
          if (isEspresso &&
              recipe.milkNotes != null &&
              recipe.milkNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Milk Notes', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    recipe.milkNotes!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Forked From ────────────────────────────────────────
          if (recipe.forkedFrom != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () =>
                    context.push('/recipe/${recipe.forkedFrom}'),
                child: Row(
                  children: [
                    Icon(Icons.fork_right,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Forked from another recipe',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 12),

          // ── Like + Comment Row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SocialRow(recipeId: recipeId),
          ),
        ],
      ),

      // ── Bottom Sheet ───────────────────────────────────────────
      bottomSheet: Container(
        color: AppColors.background,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Brew button (only when recipe has steps)
            if (recipe.steps != null && recipe.steps!.isNotEmpty) ...[
              GradientButton(
                onPressed: () =>
                    context.push('/recipe/$recipeId/brew'),
                child: const Text('Start Brew'),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                // Save/Bookmark toggle
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(saveNotifierProvider.notifier)
                        .toggleSave(recipeId),
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    label: Text(isSaved ? 'Saved' : 'Save'),
                  ),
                ),
                const SizedBox(width: 12),
                // Edit (owner) or Fork (non-owner)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isOwner) {
                        context.push('/recipe/$recipeId/edit');
                      } else {
                        context.push('/recipe/$recipeId/fork');
                      }
                    },
                    icon: Icon(
                      isOwner ? Icons.edit_outlined : Icons.fork_right,
                      size: 18,
                    ),
                    label: Text(isOwner ? 'Edit' : 'Fork'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    bool isOwner,
  ) {
    switch (action) {
      case 'edit':
        context.push('/recipe/$recipeId/edit');
      case 'fork':
        context.push('/recipe/$recipeId/fork');
      case 'delete':
        _confirmDelete(context, ref);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(recipeProvider.notifier)
                  .deleteRecipe(recipeId);
              if (context.mounted) context.pop();
            },
            child:
                Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Rating Section ──────────────────────────────────────────────────────────

class _RatingSection extends ConsumerWidget {
  const _RatingSection({
    required this.recipe,
    required this.recipeId,
    required this.isOwner,
  });

  final Recipe recipe;
  final String recipeId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRating = ref.watch(myRecipeRatingProvider(recipeId)).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Aggregate rating display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (recipe.avgRating != null) ...[
                Text(
                  recipe.avgRating!.toStringAsFixed(1),
                  style: AppTextStyles.ratingLarge,
                ),
                Text(
                  '/5',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                _StarRow(rating: recipe.avgRating!),
              ] else
                Text(
                  'No ratings yet',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (recipe.saveCount != null && recipe.saveCount! > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.bookmark_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${recipe.saveCount}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),

          // Interactive "Your Rating" row (hidden for recipe owner)
          if (!isOwner) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Rating',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                RatingBar.builder(
                  initialRating: myRating ?? 0,
                  minRating: 0.5,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 28,
                  unratedColor: AppColors.ratingEmpty,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.ratingFilled,
                  ),
                  onRatingUpdate: (value) {
                    ref
                        .read(recipeRatingNotifierProvider.notifier)
                        .rateRecipe(recipeId, value);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Star Row ────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

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

        return Icon(icon, size: 20, color: color);
      }),
    );
  }
}

// ── Parameters Card ─────────────────────────────────────────────────────────

class _ParametersCard extends ConsumerWidget {
  const _ParametersCard({
    required this.recipe,
    required this.isEspresso,
  });

  final Recipe recipe;
  final bool isEspresso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <Widget>[];

    // Common params
    if (recipe.doseGrams != null) {
      rows.add(_InfoRow(
          label: 'Dose', value: '${recipe.doseGrams!.toStringAsFixed(1)}g'));
    }
    if (recipe.ratio != null) {
      rows.add(_InfoRow(label: 'Ratio', value: recipe.ratio!));
    }
    if (recipe.grinderSetting != null || recipe.grindLabel != null) {
      final parts = <String>[];
      if (recipe.grinderSetting != null) parts.add(recipe.grinderSetting!);
      if (recipe.grindLabel != null) parts.add(recipe.grindLabel!);
      rows.add(_InfoRow(label: 'Grind', value: parts.join(' - ')));
    }
    if (recipe.grinderId != null) {
      rows.add(_EquipmentRow(
          label: 'Grinder', equipmentId: recipe.grinderId!));
    }
    if (recipe.waterTempC != null) {
      rows.add(_InfoRow(
          label: 'Water Temp',
          value: '${recipe.waterTempC!.toStringAsFixed(0)}°C'));
    }
    if (recipe.brewTimeSec != null) {
      rows.add(_InfoRow(
          label: 'Brew Time', value: formatStepTime(recipe.brewTimeSec!)));
    }

    // Espresso-specific
    if (isEspresso) {
      if (recipe.brewerId != null) {
        rows.add(_EquipmentRow(
            label: 'Machine', equipmentId: recipe.brewerId!));
      }
      if (recipe.yieldGrams != null) {
        rows.add(_InfoRow(
            label: 'Yield',
            value: '${recipe.yieldGrams!.toStringAsFixed(1)}g'));
      }
      if (recipe.distributionMethod != null) {
        rows.add(_InfoRow(
            label: 'Distribution', value: recipe.distributionMethod!));
      }
      if (recipe.tampPressureKg != null) {
        rows.add(_InfoRow(
            label: 'Tamp',
            value: '${recipe.tampPressureKg!.toStringAsFixed(1)}kg'));
      }
      if (recipe.preInfusionSec != null) {
        rows.add(_InfoRow(
            label: 'Pre-infusion', value: '${recipe.preInfusionSec}s'));
      }
      if (recipe.maxPressureBar != null) {
        rows.add(_InfoRow(
            label: 'Max Pressure',
            value: '${recipe.maxPressureBar!.toStringAsFixed(1)} bar'));
      }
    } else {
      // Manual-specific
      if (recipe.brewerId != null) {
        rows.add(_EquipmentRow(
            label: 'Brewer', equipmentId: recipe.brewerId!));
      }
      if (recipe.waterMl != null) {
        rows.add(_InfoRow(
            label: 'Water',
            value: '${recipe.waterMl!.toStringAsFixed(0)}ml'));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARAMETERS',
          style: AppTextStyles.kicker.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.cardDecoration,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────────────────

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
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── Equipment Row (async lookup) ────────────────────────────────────────────

class _EquipmentRow extends ConsumerWidget {
  const _EquipmentRow({required this.label, required this.equipmentId});

  final String label;
  final String equipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqAsync = ref.watch(equipmentDetailProvider(equipmentId));

    return eqAsync.when(
      data: (eq) =>
          _InfoRow(label: label, value: '${eq.brand} ${eq.model}'),
      loading: () => _InfoRow(label: label, value: '...'),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Steps Section ───────────────────────────────────────────────────────────

class _StepsSection extends StatelessWidget {
  const _StepsSection({required this.steps});

  final List<RecipeStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEPS',
          style: AppTextStyles.kicker.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatStepTime(step.stepTimeSec),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(step.description,
                          style: AppTextStyles.bodyMedium),
                      if (step.waterMl != null)
                        Text(
                          '${step.waterMl!.toStringAsFixed(0)}ml',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Social Row (Like + Comment) ─────────────────────────────────────────────

class _SocialRow extends ConsumerWidget {
  const _SocialRow({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeKey = (targetType: 'recipe', targetId: recipeId);
    final isLiked =
        ref.watch(isLikedByMeProvider(likeKey)).valueOrNull ?? false;
    final likeCount =
        ref.watch(likeCountProvider(likeKey)).valueOrNull ?? 0;

    final commentKey = (targetType: 'recipe', targetId: recipeId);
    final commentCount =
        ref.watch(commentCountProvider(commentKey)).valueOrNull ?? 0;

    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: () => ref
              .read(likeNotifierProvider.notifier)
              .toggleLike('recipe', recipeId),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 22,
                color: isLiked ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$likeCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isLiked ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Comment
        GestureDetector(
          onTap: () => context.push('/recipe/$recipeId/comments'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$commentCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
