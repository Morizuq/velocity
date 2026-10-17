// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/main.dart';

void main() {
  testWidgets(
    'Velocity dashboard renders core buckets and metrics with local persistence',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VELOCITY'), findsOneWidget);
      expect(find.text('The Clearance Bucket'), findsOneWidget);
      expect(find.text('The Milestone Bucket'), findsOneWidget);
      expect(find.text('Clearance Debt Burn-Down'), findsOneWidget);
      expect(find.text('Long-Term Wealth Horizon'), findsOneWidget);
    },
  );

  testWidgets(
    'Velocity dashboard renders on small mobile screen (360x780) with zero overflow',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('VELOCITY'), findsOneWidget);
      expect(find.text('Clearance Debt Burn-Down'), findsOneWidget);
      expect(find.text('Financial Velocity Matrix'), findsOneWidget);
    },
  );

  testWidgets(
    'Velocity dashboard renders interactive empty states when static data is cleared',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state cards
      expect(find.text('Clearance Bucket is Clean'), findsOneWidget);
      expect(find.text('No Milestone Buckets Created'), findsOneWidget);
      expect(find.text('No Long-Term Assets Logged'), findsOneWidget);
      expect(find.text('100% Debt-Free Position'), findsOneWidget);

      // Verify interactivity: scroll to and tap "Log First Debt Account" opens Add Debt modal
      final addDebtFinder = find.text('Log First Debt Account');
      await tester.scrollUntilVisible(
        addDebtFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(addDebtFinder);
      await tester.pumpAndSettle();

      expect(find.text('Add Clearance Debt'), findsOneWidget);
    },
  );

  testWidgets('Theme toggle smoothly transitions theme with circular reveal', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // In default dark mode, the toggle displays "LIGHT" to indicate action to switch to light
    expect(find.text('LIGHT'), findsOneWidget);

    // Tap theme toggle button
    await tester.tap(find.text('LIGHT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // After toggle, now in light mode, button displays "DARK"
    expect(find.text('DARK'), findsOneWidget);
  });
}
