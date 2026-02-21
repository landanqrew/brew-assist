import 'package:flutter/material.dart';

/// Placeholder screen for viewing another user's profile.
///
/// Navigated to via `/user/:id`. Will show their avatar, stats, check-in
/// history, and a follow/unfollow button.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.userId});

  /// The unique identifier of the user to display.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'User Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $userId',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
