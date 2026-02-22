import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/profile.dart';
import '../../providers/social_provider.dart';

/// Displays a list of followers or following for a given user.
enum FollowListMode { followers, following }

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.mode,
  });

  final String userId;
  final FollowListMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = mode == FollowListMode.followers
        ? ref.watch(followerListProvider(userId))
        : ref.watch(followingListProvider(userId));

    final title =
        mode == FollowListMode.followers ? 'Followers' : 'Following';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: listAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Text(
                mode == FollowListMode.followers
                    ? 'No followers yet'
                    : 'Not following anyone yet',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return _ProfileTile(profile: profiles[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text(
            'Could not load list',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Profile Tile ─────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        backgroundImage:
            profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? NetworkImage(profile.avatarUrl!)
                : null,
        child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
            ? const Icon(Icons.person,
                size: 20, color: AppColors.textSecondary)
            : null,
      ),
      title: Text(
        profile.displayName ?? profile.username,
        style: AppTextStyles.titleSmall,
      ),
      subtitle: Text(
        '@${profile.username}',
        style:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      onTap: () => context.push('/user/${profile.id}'),
    );
  }
}
