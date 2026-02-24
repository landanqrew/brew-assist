import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/profile_tab_bar.dart';
import '../../widgets/recipe_card.dart';

/// Full profile screen for viewing another user (or yourself via deep link).
///
/// Shows avatar, name, bio, follow button, stats, and tabbed content
/// with Check-ins and Recipes tabs.
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final isOwnProfile = ref.watch(authProvider).user?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          final checkInsAsync =
              ref.watch(userCheckInsByIdProvider(widget.userId));
          final followingCount =
              ref.watch(followingCountProvider(widget.userId)).valueOrNull ?? 0;
          final followerCount =
              ref.watch(followerCountProvider(widget.userId)).valueOrNull ?? 0;
          final checkInCount = checkInsAsync.when(
            data: (items) => items.length,
            loading: () => 0,
            error: (_, __) => 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surface,
                  backgroundImage: profile.avatarUrl != null &&
                          profile.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null ||
                          profile.avatarUrl!.isEmpty
                      ? const Icon(Icons.person,
                          size: 40, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(height: 16),

                // Display name
                Text(
                  profile.displayName ?? profile.username,
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // @username
                Text(
                  '@${profile.username}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                // Bio
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

                // Follow / Unfollow button
                if (!isOwnProfile) _FollowButton(userId: widget.userId),
                if (!isOwnProfile) const SizedBox(height: 24),

                // Stats row
                _StatsRow(
                  checkInCount: checkInCount,
                  followingCount: followingCount,
                  followerCount: followerCount,
                  onFollowingTap: () =>
                      context.push('/user/${widget.userId}/following'),
                  onFollowersTap: () =>
                      context.push('/user/${widget.userId}/followers'),
                ),
                const SizedBox(height: 24),

                // ── Tab bar ──────────────────────────────────────────
                ProfileTabBar(
                  labels: const ['Check-ins', 'Recipes'],
                  selectedIndex: _selectedTab,
                  onSelected: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 16),

                // ── Tab content ──────────────────────────────────────
                if (_selectedTab == 0)
                  _CheckInsSection(checkInsAsync: checkInsAsync),
                if (_selectedTab == 1)
                  _RecipesSection(userId: widget.userId),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Could not load profile',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(userProfileProvider(widget.userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Follow Button ────────────────────────────────────────────────────────────

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing =
        ref.watch(isFollowingProvider(userId)).valueOrNull ?? false;
    final notifier = ref.read(followNotifierProvider.notifier);

    return SizedBox(
      width: double.infinity,
      child: isFollowing
          ? OutlinedButton(
              onPressed: () => notifier.unfollow(userId),
              child: const Text('Following'),
            )
          : ElevatedButton(
              onPressed: () => notifier.follow(userId),
              child: const Text('Follow'),
            ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────────

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
    return Container(width: 1, height: 32, color: AppColors.border);
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
            Text('$count', style: AppTextStyles.statNumber),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      ),
    );
  }
}

// ── Check-ins Section ────────────────────────────────────────────────────────

class _CheckInsSection extends StatelessWidget {
  const _CheckInsSection({required this.checkInsAsync});

  final AsyncValue<List<UserCheckIn>> checkInsAsync;

  @override
  Widget build(BuildContext context) {
    return checkInsAsync.when(
      data: (checkIns) {
        if (checkIns.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No check-ins yet',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }
        return Column(
          children: checkIns
              .map((c) => _CompactCheckInItem(checkIn: c))
              .toList(),
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
          child: Center(
            child: Text(
              'Could not load check-ins',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recipes Section ──────────────────────────────────────────────────────────

class _RecipesSection extends ConsumerWidget {
  const _RecipesSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(userRecipesFeedByIdProvider(userId));

    return recipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recipes yet',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
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
          child: Center(
            child: Text(
              'Could not load recipes',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact Check-in Item ────────────────────────────────────────────────────

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
                        if (checkIn.roasterName != null)
                          Flexible(
                            child: Text(
                              checkIn.roasterName!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (checkIn.roasterName != null &&
                            checkIn.brewMethod != null)
                          Text(
                            '  \u2022  ',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        if (checkIn.brewMethod != null)
                          Text(
                            checkIn.brewMethod!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
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
