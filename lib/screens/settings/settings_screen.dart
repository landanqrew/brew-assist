import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Settings screen with list-style layout following the Vivino reference.
///
/// Sections:
/// - **Account** — email (read-only)
/// - **App** — about row
/// - **Danger zone** — sign out button
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final email = authState.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── Account Section ──────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(indent: 16, endIndent: 16),

          // ── App Section ──────────────────────────────────────────────
          _SectionHeader(title: 'App'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About brew-assist'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(indent: 16, endIndent: 16),

          // ── Danger Zone ──────────────────────────────────────────────
          _SectionHeader(title: 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'Sign Out',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'brew-assist',
        applicationVersion: '1.0.0',
        applicationIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.coffee,
            color: AppColors.white,
            size: 28,
          ),
        ),
        children: [
          Text(
            'A social coffee app for enthusiasts to log brews, share '
            'recipes, discover new coffees, and connect with fellow '
            'coffee lovers.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
