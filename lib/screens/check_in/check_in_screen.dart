import 'package:flutter/material.dart';

/// Placeholder screen for creating a new coffee check-in.
///
/// Will become a multi-step flow: pick coffee -> rate -> add details -> submit.
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Check-in')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'New Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Log what you\'re drinking right now.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
