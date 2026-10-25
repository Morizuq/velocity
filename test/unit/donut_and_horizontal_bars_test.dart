import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velocity/core/theme/velocity_tokens.dart';
import 'package:velocity/features/dashboard/presentation/widgets/velocity_donut_chart.dart';
import 'package:velocity/features/dashboard/presentation/widgets/velocity_horizontal_bars.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double width = 320}) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [VelocityTokens.dark]),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  group('VelocityDonutChart Layout & Overflow Tests', () {
    testWidgets(
      'renders long labels and percentage without overflow or collisions',
      (WidgetTester tester) async {
        final slices = [
          const VelocityDonutSlice(
            label: 'Spotify',
            amount: 2700,
            color: Colors.green,
          ),
          const VelocityDonutSlice(
            label: 'Airtel ODU',
            amount: 25000,
            color: Colors.orange,
          ),
          const VelocityDonutSlice(
            label: 'Clearance and CDS ghosting with extra long title',
            amount: 40000,
            color: Colors.teal,
          ),
        ];

        // Test on narrow mobile card (290px available width)
        await tester.pumpWidget(
          buildTestableWidget(VelocityDonutChart(slices: slices), width: 290),
        );
        await tester.pumpAndSettle();

        // Zero Flutter overflow errors
        expect(tester.takeException(), isNull);

        // Verify labels and percentages rendered
        expect(find.text('Spotify'), findsOneWidget);
        expect(find.text('Airtel ODU'), findsOneWidget);
        expect(
          find.textContaining('Clearance and CDS ghosting'),
          findsOneWidget,
        );
        expect(find.text('59%'), findsOneWidget);
        expect(find.text('37%'), findsOneWidget);
        expect(find.text('4%'), findsOneWidget);
      },
    );

    testWidgets('renders gracefully on ultra narrow 240px container', (
      WidgetTester tester,
    ) async {
      final slices = [
        const VelocityDonutSlice(
          label: 'Airtel Broadband',
          amount: 25000,
          color: Colors.orange,
        ),
        const VelocityDonutSlice(
          label: 'Office Rent & Service',
          amount: 75000,
          color: Colors.blue,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(VelocityDonutChart(slices: slices), width: 240),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('VelocityHorizontalBars Layout & Overflow Tests', () {
    testWidgets(
      'renders horizontal bars with right-aligned tabular numbers cleanly',
      (WidgetTester tester) async {
        final items = [
          const VelocityHorizontalBarItem(
            label: 'Income',
            value: 477000,
            color: Colors.teal,
          ),
          const VelocityHorizontalBarItem(
            label: 'Recurring',
            value: 67500,
            color: Colors.red,
          ),
          const VelocityHorizontalBarItem(
            label: 'Debt payments',
            value: 0,
            color: Colors.grey,
          ),
          const VelocityHorizontalBarItem(
            label: 'Free',
            value: 409500,
            color: Colors.teal,
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(VelocityHorizontalBars(items: items), width: 290),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Recurring'), findsOneWidget);
        expect(find.text('Debt payments'), findsOneWidget);
        expect(find.text('Free'), findsOneWidget);
        expect(find.text('₦477,000'), findsOneWidget);
        expect(find.text('₦67,500'), findsOneWidget);
        expect(find.text('₦0'), findsOneWidget);
        expect(find.text('₦409,500'), findsOneWidget);
      },
    );
  });
}
