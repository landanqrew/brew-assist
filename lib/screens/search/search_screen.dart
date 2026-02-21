import 'package:flutter/material.dart';

/// Placeholder screen for search and discovery.
///
/// Will support searching coffees, roasters, recipes, and users.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Find coffees, roasters, recipes, and people.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
