import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/social_provider.dart';
import 'small_chip.dart';

/// A card widget for displaying a recipe in the browse list.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.item});

  final RecipeFeedItem item;

  @override
  Widget build(BuildContext context) {
    final recipe = item.recipe;

    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}'),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar, name, time ago
              _HeaderRow(item: item),
              const SizedBox(height: 12),

              // Title
              Text(
                recipe.title,
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Brew method chip
              SmallChip(label: recipe.brewMethod),

              // Key params
              if (_hasParams(recipe)) ...[
                const SizedBox(height: 10),
                _ParamsRow(recipe: recipe),
              ],

              // Description preview
              if (recipe.description != null &&
                  recipe.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  recipe.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Bottom row: like, comment, save
              const SizedBox(height: 12),
              _BottomRow(recipeId: recipe.id),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasParams(Recipe r) {
    return r.doseGrams != null ||
        r.yieldGrams != null ||
        r.waterMl != null ||
        r.ratio != null ||
        r.brewTimeSec != null;
  }
}

// ── Header Row ──────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.item});

  final RecipeFeedItem item;

  @override
  Widget build(BuildContext context) {
    final displayName =
        item.authorDisplayName ?? item.authorUsername ?? 'Unknown';
    final username = item.authorUsername ?? '';

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/user/${item.recipe.userId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surface,
                backgroundImage: item.authorAvatarUrl != null &&
                        item.authorAvatarUrl!.isNotEmpty
                    ? NetworkImage(item.authorAvatarUrl!)
                    : null,
                child: item.authorAvatarUrl == null ||
                        item.authorAvatarUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          timeago.format(item.recipe.createdAt),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Params Row ──────────────────────────────────────────────────────────────

class _ParamsRow extends StatelessWidget {
  const _ParamsRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final pills = <String>[];
    if (recipe.doseGrams != null) {
      pills.add('${recipe.doseGrams!.toStringAsFixed(1)}g');
    }
    if (recipe.yieldGrams != null) {
      pills.add('${recipe.yieldGrams!.toStringAsFixed(1)}g yield');
    } else if (recipe.waterMl != null) {
      pills.add('${recipe.waterMl!.toStringAsFixed(0)}ml');
    }
    if (recipe.ratio != null) pills.add(recipe.ratio!);
    if (recipe.brewTimeSec != null) pills.add(formatStepTime(recipe.brewTimeSec!));

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: pills.map((p) => SmallChip(label: p)).toList(),
    );
  }
}

// ── Bottom Row (Like + Comment + Save) ──────────────────────────────────────

class _BottomRow extends ConsumerWidget {
  const _BottomRow({required this.recipeId});

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

    final isSaved =
        ref.watch(isSavedByMeProvider(recipeId)).valueOrNull ?? false;

    return Row(
      children: [
        // Like button
        InkWell(
          onTap: () => ref
              .read(likeNotifierProvider.notifier)
              .toggleLike('recipe', recipeId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isLiked ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isLiked ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Comment button
        InkWell(
          onTap: () => context.push('/recipe/$recipeId/comments'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$commentCount',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Save/bookmark button
        InkWell(
          onTap: () =>
              ref.read(saveNotifierProvider.notifier).toggleSave(recipeId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 22,
              color: isSaved ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
