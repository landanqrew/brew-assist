import 'package:flutter/material.dart';

/// Placeholder screen for a roaster's detail page.
///
/// Navigated to via `/roaster/:id`. Will show roaster info and their coffees.
class RoasterDetailScreen extends StatelessWidget {
  const RoasterDetailScreen({super.key, required this.roasterId});

  /// The unique identifier of the roaster to display.
  final String roasterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roaster')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Roaster Detail',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $roasterId',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
