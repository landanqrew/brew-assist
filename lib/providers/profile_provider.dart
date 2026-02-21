import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import 'auth_provider.dart';

// ── Profile Provider ────────────────────────────────────────────────────────

/// A [StateNotifier] that manages profile update operations.
///
/// Works alongside [AuthNotifier] — after a successful update it calls
/// [AuthNotifier.refreshProfile] so the auth state stays in sync.
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Updates the current user's profile fields.
  ///
  /// Only non-null parameters are written to the database. After a successful
  /// update the auth provider's profile is refreshed so the rest of the app
  /// sees the new data immediately.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    state = const AsyncLoading();

    try {
      final updates = <String, dynamic>{};

      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await supabase.from('profiles').update(updates).eq('id', user.id);

      // Re-fetch the profile through the auth notifier so the whole app
      // picks up the changes.
      await _ref.read(authProvider.notifier).refreshProfile();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider for profile update operations.
///
/// Usage:
/// ```dart
/// final profileState = ref.watch(profileProvider);
/// await ref.read(profileProvider.notifier).updateProfile(displayName: 'New');
/// ```
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref);
});

// ── Check-in Count Provider ─────────────────────────────────────────────────

/// Fetches the total number of check-ins for the current user.
///
/// Returns 0 if no user is logged in or on error.
final checkInCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId == null) return 0;

  try {
    final response = await supabase
        .from('check_ins')
        .select()
        .eq('user_id', userId)
        .count();
    return response.count;
  } catch (_) {
    return 0;
  }
});
