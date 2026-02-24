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
import '../../providers/recipe_provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/profile_tab_bar.dart';
import '../../widgets/recipe_card.dart';

/// The current user's profile screen.
///
/// Displays the user's avatar, display name, username, stats row
/// (check-ins / following / followers), and tabbed content area
/// with Check-ins, Recipes, and Saved tabs.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final userId = authState.user?.id;
    final userCheckIns = ref.watch(userCheckInsProvider);

    final followingCount = userId != null
        ? ref.watch(followingCountProvider(userId)).valueOrNull ?? 0
        : 0;
    final followerCount = userId != null
        ? ref.watch(followerCountProvider(userId)).valueOrNull ?? 0
        : 0;

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
                    followingCount: followingCount,
                    followerCount: followerCount,
                    onFollowingTap: userId != null
                        ? () => context.push('/user/$userId/following')
                        : null,
                    onFollowersTap: userId != null
                        ? () => context.push('/user/$userId/followers')
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Tab bar ────────────────────────────────────────────
                  ProfileTabBar(
                    labels: const ['Check-ins', 'Recipes', 'Saved'],
                    selectedIndex: _selectedTab,
                    onSelected: (i) => setState(() => _selectedTab = i),
                  ),
                  const SizedBox(height: 16),

                  // ── Tab content ────────────────────────────────────────
                  if (_selectedTab == 0)
                    _CheckInsSection(checkInsAsync: userCheckIns),
                  if (_selectedTab == 1) const _RecipesSection(),
                  if (_selectedTab == 2) const _SavedRecipesSection(),
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
  const _StatsRow({
    required this.checkInCount,
    required this.followingCount,
    required this.followerCount,
    this.onFollowingTap,
    this.onFollowersTap,
  });

  final int checkInCount;
  final int followingCount;
  final int followerCount;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            _StatColumn(count: checkInCount, label: 'Check-ins'),
            _divider(),
            _StatColumn(
              count: followingCount,
              label: 'Following',
              onTap: onFollowingTap,
            ),
            _divider(),
            _StatColumn(
              count: followerCount,
              label: 'Followers',
              onTap: onFollowersTap,
            ),
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
  const _StatColumn({
    required this.count,
    required this.label,
    this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
      ),
    );
  }
}

// ── Check-ins Section ───────────────────────────────────────────────────────

class _CheckInsSection extends StatelessWidget {
  const _CheckInsSection({required this.checkInsAsync});

  final AsyncValue<List<UserCheckIn>> checkInsAsync;

  @override
  Widget build(BuildContext context) {
    return checkInsAsync.when(
      data: (checkIns) {
        if (checkIns.isEmpty) {
          return _EmptyState(
            icon: Icons.coffee_outlined,
            title: 'No check-ins yet',
            subtitle: 'Start by checking in your first coffee!',
            actionLabel: 'Check In',
            onAction: () => context.go('/check-in'),
          );
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
    );
  }
}

// ── Recipes Section ─────────────────────────────────────────────────────────

class _RecipesSection extends ConsumerWidget {
  const _RecipesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(userRecipesFeedProvider);

    return recipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No recipes yet',
            subtitle: 'Share your first brew recipe!',
            actionLabel: 'Create Recipe',
            onAction: () => context.push('/recipe/new'),
          );
        }
        return Column(
          children: recipes.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecipeCard(item: item),
          )).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 32, color: AppColors.error),
              const SizedBox(height: 8),
              Text(
                'Could not load recipes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saved Recipes Section ───────────────────────────────────────────────────

class _SavedRecipesSection extends ConsumerWidget {
  const _SavedRecipesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedRecipesProvider);

    return savedAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return _EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved recipes',
            subtitle: 'Bookmark recipes to find them here later.',
          );
        }
        return Column(
          children: recipes.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecipeCard(item: item),
          )).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 32, color: AppColors.error),
              const SizedBox(height: 8),
              Text(
                'Could not load saved recipes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
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
