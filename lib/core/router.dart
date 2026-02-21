import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/check_in/check_in_screen.dart';
import '../screens/coffee_detail/coffee_detail_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/profile/profile_screen.dart';
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
final _shellNavigatorSearchKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _shellNavigatorCheckInKey =
    GlobalKey<NavigatorState>(debugLabel: 'checkIn');
final _shellNavigatorRecipesKey =
    GlobalKey<NavigatorState>(debugLabel: 'recipes');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

/// The application's [GoRouter] configuration.
///
/// Structure:
/// - [StatefulShellRoute.indexedStack] provides the bottom tab navigation
///   (Feed, Search, Check-in, Recipes, Profile) with independent navigation
///   stacks per tab.
/// - Additional routes that live outside the tab shell (detail screens, auth).
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/feed',
  routes: [
    // ── Bottom Tab Navigation ────────────────────────────────────────────
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
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CheckInScreen(),
              ),
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

    // ── Detail Routes (outside tabs, full-screen) ────────────────────────
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
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── Auth Routes (outside tabs, full-screen) ──────────────────────────
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
