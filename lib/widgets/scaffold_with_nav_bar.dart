import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

/// A scaffold that wraps the current tab content with a bottom [NavigationBar].
///
/// Used as the shell for [StatefulShellRoute.indexedStack] so that each tab
/// maintains its own navigation stack and scroll position.
///
/// The five tabs are:
///   0 — Feed   (home)
///   1 — Search (search)
///   2 — +      (check-in, accent-colored)
///   3 — Recipes (menu_book)
///   4 — Profile (person)
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  /// The [StatefulNavigationShell] provided by GoRouter's
  /// [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(index, context),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 32),
            selectedIcon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onTap(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      // Navigate to the initial location of the branch when tapping the
      // item that is already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
