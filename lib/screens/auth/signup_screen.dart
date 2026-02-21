import 'package:flutter/material.dart';

/// Placeholder sign-up screen.
///
/// Will allow new users to create an account via email or social providers.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
                'Join brew-assist',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to start your coffee journey.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Sign-up Screen — Coming Soon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
