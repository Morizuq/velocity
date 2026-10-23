import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/clearance/domain/entities/debt_entity.dart';
import '../../features/expenses/domain/entities/cashflow_direction.dart';
import '../../features/expenses/domain/entities/recurring_cashflow_entity.dart';
import '../../features/milestones/domain/entities/milestone_entity.dart';
import '../../features/receivables/domain/entities/receivable_entity.dart';
import '../../features/receivables/domain/entities/receivable_type.dart';

/// Seeds default redesign sample data on first launch or when requested.
class SampleDataSeeder {
  static const _seededKey = 'velocity_sample_seeded_v1';
  static const _cashflowKey = 'velocity_recurring_cashflows';
  static const _debtsKey = 'velocity_debts_clearance';
  static const _receivablesKey = 'velocity_receivables';
  static const _milestonesKey = 'velocity_milestones';

  static Future<void> seedIfEmpty(SharedPreferences prefs) async {
    if (prefs.containsKey(_seededKey)) return;

    final cashflows = [
      const RecurringCashflowEntity(
        id: 'inc_1',
        title: 'Client retainer',
        amount: 650000,
        direction: CashflowDirection.inflowReceivable,
        dayOfMonth: 1,
        category: 'Income',
        sortIndex: 0,
      ),
      const RecurringCashflowEntity(
        id: 'inc_2',
        title: 'Freelance builds',
        amount: 300000,
        direction: CashflowDirection.inflowReceivable,
        dayOfMonth: 15,
        category: 'Income',
        sortIndex: 1,
      ),
      const RecurringCashflowEntity(
        id: 'exp_1',
        title: 'Rent',
        amount: 180000,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 1,
        category: 'Housing',
        sortIndex: 0,
      ),
      const RecurringCashflowEntity(
        id: 'exp_2',
        title: 'Data and internet',
        amount: 25000,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 5,
        category: 'Utilities',
        sortIndex: 1,
      ),
      const RecurringCashflowEntity(
        id: 'exp_3',
        title: 'Food',
        amount: 120000,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 0,
        category: 'Living',
        sortIndex: 2,
      ),
      const RecurringCashflowEntity(
        id: 'exp_4',
        title: 'Subscriptions',
        amount: 30000,
        direction: CashflowDirection.outflowPayable,
        dayOfMonth: 12,
        category: 'Entertainment',
        sortIndex: 3,
      ),
    ];

    final debts = [
      DebtEntity(
        id: 'debt_1',
        creditor: 'Equipment loan',
        totalOwed: 900000,
        amountPaid: 300000,
        monthlyPayment: 75000,
        dueDate: DateTime.tryParse('2026-11-05'),
        sortIndex: 0,
      ),
      DebtEntity(
        id: 'debt_2',
        creditor: 'Borrowed from a friend',
        totalOwed: 150000,
        amountPaid: 50000,
        monthlyPayment: 25000,
        dueDate: DateTime.tryParse('2026-10-15'),
        sortIndex: 1,
      ),
    ];

    final receivables = [
      ReceivableEntity(
        id: 'recv_1',
        debtor: 'Dollz Interiors site',
        totalAmount: 400000,
        amountReceived: 150000,
        type: ReceivableType.freelanceInvoice,
        issueDate: DateTime.now(),
        dueDate: DateTime.tryParse('2026-10-30'),
        sortIndex: 0,
      ),
      ReceivableEntity(
        id: 'recv_2',
        debtor: 'App maintenance',
        totalAmount: 120000,
        amountReceived: 0,
        type: ReceivableType.freelanceInvoice,
        issueDate: DateTime.now(),
        dueDate: DateTime.tryParse('2026-10-10'),
        sortIndex: 1,
      ),
    ];

    final milestones = [
      const MilestoneEntity(
        id: 'goal_1',
        title: 'Emergency fund',
        targetAmount: 1500000,
        currentAmount: 400000,
        sortIndex: 0,
      ),
      const MilestoneEntity(
        id: 'goal_2',
        title: 'New laptop',
        targetAmount: 1200000,
        currentAmount: 200000,
        sortIndex: 1,
      ),
    ];

    await prefs.setString(
      _cashflowKey,
      jsonEncode(cashflows.map((c) => c.toMap()).toList()),
    );
    await prefs.setString(
      _debtsKey,
      jsonEncode(debts.map((d) => d.toMap()).toList()),
    );
    await prefs.setString(
      _receivablesKey,
      jsonEncode(receivables.map((r) => r.toMap()).toList()),
    );
    await prefs.setString(
      _milestonesKey,
      jsonEncode(milestones.map((m) => m.toMap()).toList()),
    );

    await prefs.setBool(_seededKey, true);
  }

  static Future<void> purgeSampleDataIfPresent(SharedPreferences prefs) async {
    if (prefs.getBool('velocity_dummy_data_purged_v1') == true) return;
    await prefs.remove(_cashflowKey);
    await prefs.remove(_debtsKey);
    await prefs.remove('velocity_clearance_debts');
    await prefs.remove(_receivablesKey);
    await prefs.remove(_milestonesKey);
    await prefs.remove(_seededKey);
    await prefs.setBool('velocity_dummy_data_purged_v1', true);
  }

  static Future<void> resetData(SharedPreferences prefs) async {
    await prefs.remove(_cashflowKey);
    await prefs.remove(_debtsKey);
    await prefs.remove('velocity_clearance_debts');
    await prefs.remove(_receivablesKey);
    await prefs.remove(_milestonesKey);
    await prefs.remove(_seededKey);
    await prefs.setBool('velocity_dummy_data_purged_v1', true);
  }
}
