import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/core/theme/velocity_tokens.dart';
import 'package:velocity/features/clearance/presentation/clearance_page.dart';
import 'package:velocity/features/clearance/presentation/controllers/clearance_controller.dart';
import 'package:velocity/shared/design_system/widgets/velocity_payment_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VelocityPaymentSheet Quick Actions and Comma Formatter Tests', () {
    testWidgets('Pay half and Clear all buttons populate formatted commas in payment sheet', (
      WidgetTester tester,
    ) async {
      double? confirmedAmount;
      DateTime? confirmedDate;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [VelocityTokens.dark]),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  VelocityPaymentSheet.show(
                    context,
                    title: 'Log payment: Bank loan',
                    maxAmount: 250000,
                    onConfirm: (amount, date) {
                      confirmedAmount = amount;
                      confirmedDate = date;
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Quick action buttons are present
      expect(find.text('Pay half'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);

      // Tap "Pay half" (half of 250,000 is 125,000)
      await tester.tap(find.text('Pay half'));
      await tester.pump();

      // Verify textfield populated with commas: "125,000"
      expect(find.text('125,000'), findsOneWidget);

      // Tap "Clear all" (full 250,000)
      await tester.tap(find.text('Clear all'));
      await tester.pump();

      // Verify textfield populated with commas: "250,000"
      expect(find.text('250,000'), findsOneWidget);

      // Confirm payment
      await tester.tap(find.text('Log payment'));
      await tester.pumpAndSettle();

      expect(confirmedAmount, equals(250000.0));
      expect(confirmedDate, isNotNull);
    });

    testWidgets('Manual input formats with commas in real time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [VelocityTokens.dark]),
          home: Scaffold(
            body: VelocityPaymentSheet(
              title: 'Log payment',
              maxAmount: 1000000,
              onConfirm: (amount, date) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 450000 into the amount input
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, '450000');
      await tester.pump();

      // Verify it is formatted as "450,000"
      expect(find.text('450,000'), findsOneWidget);
    });
  });

  group('ClearancePage Collapsed Cleared Section Tests', () {
    testWidgets('Cleared debts move to bottom collapsed section and can be expanded and undone', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Add two debts: one active (Owed 100,000) and one cleared (Owed 50,000, Paid 50,000)
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Active Debt', totalOwed: 100000, initialPaid: 0);
      notifier.addDebt(creditor: 'Completed Debt', totalOwed: 50000, initialPaid: 50000);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [VelocityTokens.dark]),
            home: const ClearancePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Active Debt is visible in main section with "Top priority"
      expect(find.text('Active Debt'), findsOneWidget);
      expect(find.text('Top priority'), findsOneWidget);

      // Collapsed Cleared section header is displayed at bottom
      expect(find.text('Cleared debts'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Show'), findsOneWidget);

      // Tap "Show" / header to expand
      await tester.tap(find.text('Cleared debts'));
      await tester.pumpAndSettle();

      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('Completed Debt'), findsOneWidget);
      expect(find.text('Undo cleared'), findsOneWidget);

      // Tap "Undo cleared"
      await tester.tap(find.text('Undo cleared'));
      await tester.pumpAndSettle();

      // Now both debts are active
      expect(find.text('Top priority'), findsOneWidget);
      expect(find.text('Priority 2'), findsOneWidget);
      expect(find.text('Completed Debt'), findsOneWidget);
      expect(find.text('Active Debt'), findsOneWidget);
    });
  });
}
