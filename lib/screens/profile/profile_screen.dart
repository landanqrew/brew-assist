import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/profile_provider.dart';

/// The current user's profile screen.
///
/// Displays the user's avatar, display name, username, stats row
/// (check-ins / following / followers), and recent check-in history.
/// Follows the Vivino-style design from PLAN.md.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final userCheckIns = ref.watch(userCheckInsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Avatar ─────────────────────────────────────────────
                  _ProfileAvatar(avatarUrl: profile.avatarUrl),
                  const SizedBox(height: 16),

                  // ── Display name ───────────────────────────────────────
                  Text(
                    profile.displayName ?? profile.username,
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // ── @username ──────────────────────────────────────────
                  Text(
                    '@${profile.username}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // ── Bio ────────────────────────────────────────────────
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile.bio!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Edit profile button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/profile/edit'),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats row ──────────────────────────────────────────
                  _StatsRow(
                    checkInCount: userCheckIns.when(
                      data: (items) => items.length,
                      loading: () => ref
                          .watch(checkInCountProvider)
                          .whenOrNull(data: (c) => c) ?? 0,
                      error: (_, __) => 0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Check-ins section ───────────────────────────
                  _RecentCheckInsSection(checkInsAsync: userCheckIns),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Profile Avatar ──────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.surface,
      backgroundImage:
          avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? const Icon(
              Icons.person,
              size: 40,
              color: AppColors.textSecondary,
            )
          : null,
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.checkInCount});

  final int checkInCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            _StatColumn(count: checkInCount, label: 'Check-ins'),
            _divider(),
            const _StatColumn(count: 0, label: 'Following'),
            _divider(),
            const _StatColumn(count: 0, label: 'Followers'),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTextStyles.statNumber,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.statLabel,
          ),
        ],
      ),
    );
  }
}

// ── Recent Check-ins Section ────────────────────────────────────────────────

class _RecentCheckInsSection extends StatelessWidget {
  const _RecentCheckInsSection({required this.checkInsAsync});

  final AsyncValue<List<UserCheckIn>> checkInsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your recent check-ins',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        checkInsAsync.when(
          data: (checkIns) {
            if (checkIns.isEmpty) {
              return _EmptyCheckIns();
            }
            return Column(
              children: checkIns
                  .map((checkIn) => _CompactCheckInItem(checkIn: checkIn))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 32,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load check-ins',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty Check-ins Card ────────────────────────────────────────────────────

class _EmptyCheckIns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.coffee_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No check-ins yet',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by checking in your first coffee!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/check-in'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact Check-in Item ───────────────────────────────────────────────────

/// A compact list-style representation of a check-in, used on the profile
/// screen. Shows coffee name, rating, brew method, and date in a clean row.
class _CompactCheckInItem extends StatelessWidget {
  const _CompactCheckInItem({required this.checkIn});

  final UserCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.MMMd().format(checkIn.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/coffee/${checkIn.coffeeId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Coffee info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn.coffeeName ?? 'Unknown Coffee',
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (checkIn.roasterName != null) ...[
                          Flexible(
                            child: Text(
                              checkIn.roasterName!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (checkIn.roasterName != null &&
                            checkIn.brewMethod != null)
                          Text(
                            '  \u2022  ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (checkIn.brewMethod != null)
                          Text(
                            checkIn.brewMethod!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Rating + date column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        checkIn.rating.toStringAsFixed(1),
                        style: AppTextStyles.ratingSmall,
                      ),
                      const SizedBox(width: 4),
                      RatingBarIndicator(
                        rating: checkIn.rating,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.ratingFilled,
                        ),
                        unratedColor: AppColors.ratingEmpty,
                        itemCount: 5,
                        itemSize: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
