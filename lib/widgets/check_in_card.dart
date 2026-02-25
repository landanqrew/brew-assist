import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/feed_provider.dart';
import '../providers/social_provider.dart';

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

            // ── Preparation + venue type chips ────────────────────────
            if (item.brewMethod != null ||
                item.specialtyDrink != null ||
                item.venueType != null) ...[
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

            // ── Photo ──────────────────────────────────────────────────
            if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PhotoSection(photoUrl: item.photoUrl!),
            ],

            // ── Bottom row: like + comment ───────────────────────────
            const SizedBox(height: 12),
            _BottomRow(checkInId: item.id),
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
        // Avatar + name — tappable to user profile
        GestureDetector(
          onTap: () => context.push('/user/${item.userId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surface,
                backgroundImage:
                    item.avatarUrl != null && item.avatarUrl!.isNotEmpty
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

// ── Preparation / Venue Type Chips ───────────────────────────────────────────

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
        if (item.specialtyDrink != null && item.specialtyDrink!.isNotEmpty)
          _SmallChip(label: item.specialtyDrink!),
        if (item.venueType != null)
          _SmallChip(label: _venueTypeLabel(item.venueType!)),
      ],
    );
  }

  String _venueTypeLabel(String type) {
    switch (type) {
      case 'home':
        return 'Home';
      case 'cafe':
        return 'Cafe';
      case 'other':
        return 'Other';
      default:
        return type;
    }
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

// ── Photo Section ────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _PhotoViewer(photoUrl: photoUrl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              color: AppColors.surface,
            ),
            errorWidget: (_, __, ___) => Container(
              height: 200,
              color: AppColors.surface,
              child: const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Photo Viewer ─────────────────────────────────────────────────────────────

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Row (Like + Comment) ──────────────────────────────────────────────

class _BottomRow extends ConsumerWidget {
  const _BottomRow({required this.checkInId});

  final String checkInId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeKey = (targetType: 'check_in', targetId: checkInId);
    final isLiked = ref.watch(isLikedByMeProvider(likeKey)).valueOrNull ?? false;
    final likeCount = ref.watch(likeCountProvider(likeKey)).valueOrNull ?? 0;

    final commentKey = (targetType: 'check_in', targetId: checkInId);
    final commentCount =
        ref.watch(commentCountProvider(commentKey)).valueOrNull ?? 0;

    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: () => ref
              .read(likeNotifierProvider.notifier)
              .toggleLike('check_in', checkInId),
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
        const SizedBox(width: 16),

        // Comment button
        GestureDetector(
          onTap: () => context.push('/check-in/$checkInId/comments'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
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
      ],
    );
  }
}
