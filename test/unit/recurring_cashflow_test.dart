import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:velocity/features/expenses/domain/entities/cashflow_direction.dart';
import 'package:velocity/features/expenses/domain/entities/recurring_cashflow_entity.dart';
import 'package:velocity/features/expenses/presentation/controllers/recurring_cashflow_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecurringCashflowEntity Domain Unit Tests', () {
    test('calculates current cycle key and settlement status', () {
      final now = DateTime(2026, 10, 15);
      final cycleKey = RecurringCashflowEntity.currentCycleKey(now);
      expect(cycleKey, equals('2026-10'));

      final item = RecurringCashflowEntity(
        id: '1',
        title: 'Spotify',
        amount: 12.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 10,
        category: 'Subscription',
        lastSettledCycle: '2026-09',
      );

      // Not settled in current October cycle
      expect(item.isSettledThisMonth, isFalse);

      final settledItem = item.markSettledForCurrentCycle();
      expect(settledItem.isSettledThisMonth, isTrue);

      final unmarkedItem = settledItem.unmarkSettled();
      expect(unmarkedItem.isSettledThisMonth, isFalse);
    });

    test('computes next due date and days until due correctly', () {
      final refDate = DateTime(2026, 10, 5);
      final item = RecurringCashflowEntity(
        id: '2',
        title: 'Internet Fiber',
        amount: 80.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 12,
        category: 'Utility',
      );

      final nextDue = item.nextDueDate(refDate);
      expect(nextDue.year, equals(2026));
      expect(nextDue.month, equals(10));
      expect(nextDue.day, equals(12));
      expect(item.daysUntilDue(refDate), equals(7));
    });

    test('serializes toMap and deserializes fromMap symmetrically', () {
      final item = RecurringCashflowEntity(
        id: '3',
        title: 'Tech Work Salary',
        amount: 5000.0,
        direction: CashflowDirection.inflowReceivable,
        dayOfMonth: 25,
        category: 'Salary',
        lastSettledCycle: '2026-10',
        notes: 'Monthly direct deposit',
      );

      final map = item.toMap();
      final fromMap = RecurringCashflowEntity.fromMap(map);

      expect(fromMap.id, equals(item.id));
      expect(fromMap.title, equals(item.title));
      expect(fromMap.amount, equals(item.amount));
      expect(fromMap.direction, equals(CashflowDirection.inflowReceivable));
      expect(fromMap.dayOfMonth, equals(25));
      expect(fromMap.category, equals('Salary'));
      expect(fromMap.notes, equals('Monthly direct deposit'));
    });
  });

  group('RecurringCashflowController State Management Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('adds outflow subscriptions and inflow salaries and aggregates totals', () {
      final notifier = container.read(recurringCashflowControllerProvider.notifier);

      notifier.addCashflow(
        title: 'Internet',
        amount: 50.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 5,
        category: 'Utility',
      );

      notifier.addCashflow(
        title: 'Spotify',
        amount: 15.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 15,
        category: 'Subscription',
      );

      notifier.addCashflow(
        title: 'Engineering Salary',
        amount: 3000.0,
        direction: CashflowDirection.inflowReceivable,
        dayOfMonth: 28,
        category: 'Salary',
      );

      final items = container.read(recurringCashflowControllerProvider);
      expect(items.length, equals(3));

      // Outflows: 50 + 15 = 65
      final totalOutflow = container.read(monthlyOutflowTotalProvider);
      expect(totalOutflow, equals(65.0));

      // Inflow: 3000
      final totalInflow = container.read(monthlyInflowTotalProvider);
      expect(totalInflow, equals(3000.0));

      // Net margin: 3000 - 65 = 2935
      final netMargin = container.read(netMonthlyCashflowProvider);
      expect(netMargin, equals(2935.0));

      // Surplus cash flow means runway is infinite
      final runway = container.read(cashRunwayMonthsProvider);
      expect(runway.isInfinite, isTrue);
    });

    test('computes finite runway when cash flow is negative', () {
      final notifier = container.read(recurringCashflowControllerProvider.notifier);
      final dashboardNotifier = container.read(dashboardControllerProvider.notifier);

      // Set liquid cash to 1,000
      dashboardNotifier.updateLiquidCash(1000.0);

      // Outflows: 300
      notifier.addCashflow(
        title: 'Rent Subsidized',
        amount: 300.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 1,
        category: 'Housing',
      );

      // Outflows: 100
      notifier.addCashflow(
        title: 'Internet',
        amount: 100.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 10,
        category: 'Utility',
      );

      // Total burn = 400. Inflows = 0. Net burn = 400.
      // Liquid cash = 1000 / 400 = 2.5 months runway
      final runway = container.read(cashRunwayMonthsProvider);
      expect(runway, equals(2.5));
    });

    test('toggles settlement status for the active cycle', () {
      final notifier = container.read(recurringCashflowControllerProvider.notifier);

      notifier.addCashflow(
        title: 'Cloud VPS',
        amount: 20.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 1,
        category: 'Software',
      );

      final item = container.read(recurringCashflowControllerProvider).first;
      expect(item.isSettledThisMonth, isFalse);

      notifier.toggleSettledCurrentCycle(item.id);
      final settled = container.read(recurringCashflowControllerProvider).first;
      expect(settled.isSettledThisMonth, isTrue);

      notifier.toggleSettledCurrentCycle(item.id);
      final unsettledAgain = container.read(recurringCashflowControllerProvider).first;
      expect(unsettledAgain.isSettledThisMonth, isFalse);
    });

    test('reorders recurring items correctly', () {
      final notifier = container.read(recurringCashflowControllerProvider.notifier);

      notifier.addCashflow(
        title: 'Item A',
        amount: 10.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 1,
      );
      notifier.addCashflow(
        title: 'Item B',
        amount: 20.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 2,
      );
      notifier.addCashflow(
        title: 'Item C',
        amount: 30.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 3,
      );

      notifier.reorderCashflows(2, 0);

      final reordered = container.read(recurringCashflowControllerProvider);
      expect(reordered.first.title, equals('Item C'));
      expect(reordered[1].title, equals('Item A'));
      expect(reordered[2].title, equals('Item B'));
    });

    test('deletes cash flow item properly', () {
      final notifier = container.read(recurringCashflowControllerProvider.notifier);

      notifier.addCashflow(
        title: 'To Be Deleted',
        amount: 10.0,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 1,
      );

      final item = container.read(recurringCashflowControllerProvider).first;
      notifier.deleteCashflow(item.id);

      final remaining = container.read(recurringCashflowControllerProvider);
      expect(remaining.isEmpty, isTrue);
    });
  });
}
