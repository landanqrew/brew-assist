import 'package:flutter/material.dart';

/// Placeholder settings screen.
///
/// Will contain account preferences, notification toggles, logout, and about
/// info. Navigated to from the profile screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Account, preferences, and more.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
