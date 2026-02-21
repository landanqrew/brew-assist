import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// Form screen for editing the current user's profile.
///
/// Pre-populates display name, username (read-only), and bio from the
/// current auth state. On save, calls [ProfileNotifier.updateProfile] and
/// pops back with a success snackbar.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: profile?.username ?? '',
    );
    _bioController = TextEditingController(
      text: profile?.bio ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(profileProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
        );

    if (!mounted) return;

    final profileState = ref.read(profileProvider);
    if (profileState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState is AsyncLoading;
    final profile = ref.watch(authProvider).profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _onSave,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Avatar section ───────────────────────────────────────
              _AvatarSection(avatarUrl: profile?.avatarUrl),
              const SizedBox(height: 32),

              // ── Display name ─────────────────────────────────────────
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Username (read-only) ─────────────────────────────────
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Your username',
                  prefixText: '@',
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 20),

              // ── Bio ──────────────────────────────────────────────────
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about your coffee journey...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // ── Save button (alternative to app bar) ─────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSave,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar Section ──────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
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
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            // Photo upload will be implemented in Phase 4.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload coming soon!'),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: Text(
            'Change Photo',
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
