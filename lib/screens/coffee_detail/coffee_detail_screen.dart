import 'package:flutter/material.dart';

/// Placeholder screen for a single coffee's detail page.
///
/// Navigated to via `/coffee/:id`. Will show coffee info, aggregate rating,
/// and recent check-ins.
class CoffeeDetailScreen extends StatelessWidget {
  const CoffeeDetailScreen({super.key, required this.coffeeId});

  /// The unique identifier of the coffee to display.
  final String coffeeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Detail')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.coffee_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Coffee Detail',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $coffeeId',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
