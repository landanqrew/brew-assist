import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brew_assist/main.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BrewAssistApp()),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
