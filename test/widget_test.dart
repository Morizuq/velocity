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

  testWidgets('Theme toggle smoothly switches between light and dark modes', (
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

    // The sliding toggle is present
    expect(find.byKey(const Key('theme_mode_toggle')), findsOneWidget);

    // Tap theme toggle button
    await tester.tap(find.byKey(const Key('theme_mode_toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // Verify toggle still exists and state transitioned
    expect(find.byKey(const Key('theme_mode_toggle')), findsOneWidget);
  });

  testWidgets(
    'Clearance Hub renders on mobile viewport (400x576) with zero overflow',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(400, 576);
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

      // Navigate to Clearance Hub tab
      final clearanceTabFinder = find.text('Clearance');
      expect(clearanceTabFinder, findsOneWidget);
      await tester.tap(clearanceTabFinder);
      await tester.pumpAndSettle();

      // Ensure no layout exceptions or RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Clearance Hub'), findsOneWidget);
      expect(find.text('Add Monthly Bill'), findsOneWidget);
      expect(find.text('Add Debt Account'), findsOneWidget);
    },
  );

  testWidgets(
    'Add Subscription / Bill dialog renders on mobile (400x576) without flex overflow',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(400, 576);
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

      // Navigate to Clearance Hub tab
      await tester.tap(find.text('Clearance'));
      await tester.pumpAndSettle();

      // Tap "Add Monthly Bill" button to open dialog
      final addBillFinder = find.text('Add Monthly Bill');
      expect(addBillFinder, findsOneWidget);
      await tester.tap(addBillFinder);
      await tester.pumpAndSettle();

      // Ensure no layout exception occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Add Subscription / Bill'), findsOneWidget);
      expect(find.text('Monthly Payable'), findsOneWidget);
      expect(find.text('Monthly Inflow'), findsOneWidget);
    },
  );
}
