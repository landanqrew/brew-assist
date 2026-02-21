import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brew_assist/core/theme/app_theme.dart';
import 'package:brew_assist/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('brew-assist'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsAtLeast(2)); // email + password
  });

  testWidgets('Theme uses forest green primary', (WidgetTester tester) async {
    final theme = AppTheme.light;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, const Color(0xFF5B7F5E));
  });
}
