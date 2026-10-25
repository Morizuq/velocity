import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/features/clearance/presentation/controllers/clearance_controller.dart';
import 'package:velocity/features/milestones/presentation/controllers/milestones_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goals and Debts Edit & Undo Tests', () {
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

    test('MilestonesController updates target budget and title', () {
      final notifier = container.read(milestonesControllerProvider.notifier);
      notifier.addMilestone(title: 'New Laptop', targetAmount: 400000, initialAmount: 100000);

      var goals = container.read(milestonesControllerProvider);
      expect(goals.length, equals(1));
      expect(goals.first.targetAmount, equals(400000));
      expect(goals.first.isCompleted, isFalse);

      // Edit budget to 500,000
      notifier.editMilestone(
        milestoneId: goals.first.id,
        title: 'MacBook Pro',
        targetAmount: 500000,
      );

      goals = container.read(milestonesControllerProvider);
      expect(goals.first.title, equals('MacBook Pro'));
      expect(goals.first.targetAmount, equals(500000));
      expect(goals.first.currentAmount, equals(100000));
      expect(goals.first.remainingAmount, equals(400000));
    });

    test('ClearanceController can undo cleared debt', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Bank Loan', totalOwed: 250000, initialPaid: 0);

      var debts = container.read(clearanceControllerProvider);
      expect(debts.first.isCleared, isFalse);

      // Mark cleared
      notifier.toggleCleared(debts.first.id);
      debts = container.read(clearanceControllerProvider);
      expect(debts.first.isCleared, isTrue);
      expect(debts.first.amountPaid, equals(250000));
      expect(debts.first.remainingAmount, equals(0));

      // Undo cleared
      notifier.undoCleared(debts.first.id);
      debts = container.read(clearanceControllerProvider);
      expect(debts.first.isCleared, isFalse);
      expect(debts.first.amountPaid, equals(0));
      expect(debts.first.remainingAmount, equals(250000));
    });

    test('ClearanceController edits debt parameters', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Friend', totalOwed: 100000, initialPaid: 100000);

      var debts = container.read(clearanceControllerProvider);
      expect(debts.first.isCleared, isTrue);

      // Edit debt amount paid back to partial payment
      notifier.editDebt(
        debtId: debts.first.id,
        creditor: 'Friend A',
        totalOwed: 120000,
        amountPaid: 50000,
        monthlyPayment: 20000,
      );

      debts = container.read(clearanceControllerProvider);
      expect(debts.first.creditor, equals('Friend A'));
      expect(debts.first.totalOwed, equals(120000));
      expect(debts.first.amountPaid, equals(50000));
      expect(debts.first.remainingAmount, equals(70000));
      expect(debts.first.isCleared, isFalse);
    });

    test('ClearanceController moveActive reorders active debts while keeping cleared debts at bottom', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Debt 1', totalOwed: 50000, initialPaid: 0);
      notifier.addDebt(creditor: 'Debt 2', totalOwed: 80000, initialPaid: 0);
      notifier.addDebt(creditor: 'Debt 3', totalOwed: 30000, initialPaid: 30000); // cleared

      var debts = container.read(clearanceControllerProvider);
      expect(debts.length, equals(3));
      final debt2Id = debts[1].id;

      // Move Debt 2 to top among active debts
      notifier.moveActive(debt2Id, 'top');

      debts = container.read(clearanceControllerProvider);
      expect(debts[0].creditor, equals('Debt 2'));
      expect(debts[1].creditor, equals('Debt 1'));
      expect(debts[2].creditor, equals('Debt 3')); // Cleared stays at end
    });
  });
}
