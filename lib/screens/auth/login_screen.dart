import 'package:flutter/material.dart';

/// Placeholder login screen.
///
/// Will support email + password, Google, and Apple sign-in via Supabase Auth.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.coffee_outlined, size: 80, color: Color(0xFF5B7F5E)),
              const SizedBox(height: 24),
              Text(
                'brew-assist',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to track your coffee journey.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Login Screen — Coming Soon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
