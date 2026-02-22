import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/check_in/check_in_screen.dart';
import '../screens/coffee/add_coffee_screen.dart';
import '../screens/coffee_detail/coffee_detail_screen.dart';
import '../screens/comments/comments_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/follow_list/follow_list_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/recipe/recipe_form_screen.dart';
import '../screens/recipe_detail/recipe_detail_screen.dart';
import '../screens/recipes/recipes_screen.dart';
import '../screens/roaster_detail/roaster_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/user_profile/user_profile_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// Global navigator keys used by GoRouter for the root and shell navigators.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorFeedKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final _shellNavigatorSearchKey =
    GlobalKey<NavigatorState>(debugLabel: 'search');
final _shellNavigatorCheckInKey =
    GlobalKey<NavigatorState>(debugLabel: 'checkIn');
final _shellNavigatorRecipesKey =
    GlobalKey<NavigatorState>(debugLabel: 'recipes');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Routes that do not require authentication.
const _authRoutes = {'/login', '/signup'};

/// Provider for the application's [GoRouter] configuration.
///
/// The router uses [refreshListenable] tied to the auth state so it
/// re-evaluates its redirect on every auth status change.
final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authStateListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/feed',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isOnAuthRoute = _authRoutes.contains(state.matchedLocation);

      // While auth state is loading, don't redirect — let the current page
      // render (or stay on the initial location).
      if (authState.status == AuthStatus.loading) return null;

      // Not authenticated → force to login (unless already on an auth route).
      if (!authState.isAuthenticated) {
        return isOnAuthRoute ? null : '/login';
      }

      // Authenticated but on an auth route → redirect to feed.
      if (authState.isAuthenticated && isOnAuthRoute) {
        return '/feed';
      }

      return null;
    },
    routes: [
      // ── Bottom Tab Navigation ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0 — Feed
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFeedKey,
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FeedScreen(),
                ),
              ),
            ],
          ),

          // Tab 1 — Search
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearchKey,
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchScreen(),
                ),
              ),
            ],
          ),

          // Tab 2 — Check-in (+)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCheckInKey,
            routes: [
              GoRoute(
                path: '/check-in',
                pageBuilder: (context, state) {
                  final coffeeId =
                      state.uri.queryParameters['coffeeId'];
                  return NoTransitionPage(
                    child: CheckInScreen(coffeeId: coffeeId),
                  );
                },
              ),
            ],
          ),

          // Tab 3 — Recipes
          StatefulShellBranch(
            navigatorKey: _shellNavigatorRecipesKey,
            routes: [
              GoRoute(
                path: '/recipes',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RecipesScreen(),
                ),
              ),
            ],
          ),

          // Tab 4 — Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Detail Routes (outside tabs, full-screen) ──────────────────────
      GoRoute(
        path: '/coffee/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddCoffeeScreen(),
      ),
      GoRoute(
        path: '/coffee/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CoffeeDetailScreen(
          coffeeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/roaster/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RoasterDetailScreen(
          roasterId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/recipe/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RecipeFormScreen(),
      ),
      GoRoute(
        path: '/recipe/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeFormScreen(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/recipe/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeDetailScreen(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/user/:id/followers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FollowListScreen(
          userId: state.pathParameters['id']!,
          mode: FollowListMode.followers,
        ),
      ),
      GoRoute(
        path: '/user/:id/following',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FollowListScreen(
          userId: state.pathParameters['id']!,
          mode: FollowListMode.following,
        ),
      ),
      GoRoute(
        path: '/check-in/:id/comments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CommentsScreen(
          checkInId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Auth Routes (outside tabs, full-screen) ────────────────────────
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),
    ],
  );
});
