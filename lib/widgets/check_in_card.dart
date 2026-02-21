import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/feed_provider.dart';

/// A Vivino-inspired card widget for displaying a check-in in the feed.
///
/// Designed to look great with or without optional fields (photo, notes,
/// flavor tags, brew method, serving style).
class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key, required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar, name, username, time ago ─────────────
            _HeaderRow(item: item),
            const SizedBox(height: 12),

            // ── Coffee info ──────────────────────────────────────────
            _CoffeeInfo(item: item),
            const SizedBox(height: 10),

            // ── Rating display ───────────────────────────────────────
            _RatingRow(rating: item.rating),

            // ── Brew method + serving style chips ────────────────────
            if (item.brewMethod != null || item.servingStyle != null) ...[
              const SizedBox(height: 10),
              _MethodChips(item: item),
            ],

            // ── Flavor tags ──────────────────────────────────────────
            if (item.flavorTags != null && item.flavorTags!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _FlavorTags(tags: item.flavorTags!),
            ],

            // ── Notes preview ────────────────────────────────────────
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                item.notes!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ── Bottom row: like placeholder ─────────────────────────
            const SizedBox(height: 12),
            _BottomRow(),
          ],
        ),
      ),
    );
  }
}

// ── Header Row ───────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final displayName = item.displayName ?? item.username ?? 'Unknown';
    final username = item.username ?? '';

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surface,
          backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
              ? NetworkImage(item.avatarUrl!)
              : null,
          child: item.avatarUrl == null || item.avatarUrl!.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.textSecondary,
                )
              : null,
        ),
        const SizedBox(width: 10),

        // Name + username
        Expanded(
          child: Column(
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
        ),

        // Time ago
        Text(
          timeago.format(item.createdAt),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Coffee Info ──────────────────────────────────────────────────────────────

class _CoffeeInfo extends StatelessWidget {
  const _CoffeeInfo({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/coffee/${item.coffeeId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.coffeeName ?? 'Unknown Coffee',
            style: AppTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.roasterName != null) ...[
            const SizedBox(height: 2),
            Text(
              item.roasterName!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Rating Row ───────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.ratingSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, _) => const Icon(
            Icons.star_rounded,
            color: AppColors.ratingFilled,
          ),
          unratedColor: AppColors.ratingEmpty,
          itemCount: 5,
          itemSize: 16,
        ),
      ],
    );
  }
}

// ── Method / Serving Style Chips ─────────────────────────────────────────────

class _MethodChips extends StatelessWidget {
  const _MethodChips({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (item.brewMethod != null)
          _SmallChip(label: item.brewMethod!),
        if (item.servingStyle != null)
          _SmallChip(label: item.servingStyle!),
      ],
    );
  }
}

// ── Flavor Tags ──────────────────────────────────────────────────────────────

class _FlavorTags extends StatelessWidget {
  const _FlavorTags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((tag) => _SmallChip(label: tag)).toList(),
    );
  }
}

// ── Small Chip ───────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Bottom Row (Like Placeholder) ────────────────────────────────────────────

class _BottomRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.favorite_border_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '0',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
