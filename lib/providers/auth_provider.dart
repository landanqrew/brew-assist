import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../models/profile.dart';

// ── Auth State ───────────────────────────────────────────────────────────────

/// Represents the possible authentication states of the app.
enum AuthStatus { loading, authenticated, unauthenticated }

/// Immutable snapshot of the current authentication state.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.profile,
  });

  final AuthStatus status;
  final User? user;
  final Profile? profile;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Profile? profile,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Auth Notifier ────────────────────────────────────────────────────────────

/// A [StateNotifier] that manages authentication state and exposes sign-in,
/// sign-up, and sign-out methods.
///
/// Listens to Supabase's [onAuthStateChange] stream and keeps the current
/// user's [Profile] in sync.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  StreamSubscription<AuthState>? _authSubscription;

  void _init() {
    // Check the current session immediately.
    final session = supabase.auth.currentSession;
    if (session != null) {
      _onAuthenticated(session.user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Listen for future auth state changes.
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          if (session != null) {
            _onAuthenticated(session.user);
          }
        case AuthChangeEvent.signedOut:
          state = const AuthState(status: AuthStatus.unauthenticated);
        default:
          break;
      }
    });
  }

  /// Fetches the user's profile and updates state to authenticated.
  Future<void> _onAuthenticated(User user) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final profile = data != null ? Profile.fromJson(data) : null;

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
      );
    } catch (e) {
      // Even if profile fetch fails, the user is still authenticated.
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    }
  }

  /// Re-fetches the current user's profile from the database and updates
  /// the auth state.
  ///
  /// Called after profile edits so the rest of the app picks up the changes
  /// immediately.
  Future<void> refreshProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await _onAuthenticated(user);
  }

  /// Signs in with email and password.
  ///
  /// Throws an [AuthException] on failure so that callers can display the
  /// error message in the UI.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // The onAuthStateChange listener handles the rest.
    } on AuthException {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      rethrow;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// Creates a new account with email and password, then writes the username
  /// to the `profiles` table.
  ///
  /// Throws an [AuthException] on failure.
  Future<void> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // The DB trigger creates a basic profile row. We upsert to set the
        // username properly.
        await supabase.from('profiles').upsert({
          'id': user.id,
          'username': username,
        });
      }

      // The onAuthStateChange listener handles setting authenticated state.
    } on AuthException {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      rethrow;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      // Even if the remote sign-out fails, clear local state.
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// The main auth state provider. Access anywhere via `ref.watch(authProvider)`.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// ── Auth State Listenable (for GoRouter) ─────────────────────────────────────

/// A [ChangeNotifier] that re-fires whenever the auth status changes.
///
/// Used as [GoRouter.refreshListenable] so the router re-evaluates its
/// redirect logic on every auth state transition.
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(authProvider, (previous, next) {
      // Only notify when the status actually changes (not on profile updates).
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Provider for the [AuthStateListenable] used by GoRouter.
final authStateListenableProvider = Provider<AuthStateListenable>((ref) {
  final listenable = AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
