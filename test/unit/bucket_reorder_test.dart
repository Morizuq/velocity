import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/features/assets/presentation/controllers/assets_controller.dart';
import 'package:velocity/features/clearance/presentation/controllers/clearance_controller.dart';
import 'package:velocity/features/milestones/presentation/controllers/milestones_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bucket Item Reordering Tests', () {
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

    test('ClearanceController moves bottom item to top', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Card A', totalOwed: 500);
      notifier.addDebt(creditor: 'Card B', totalOwed: 1200);
      notifier.addDebt(creditor: 'Card C', totalOwed: 3000);

      final initialDebts = container.read(clearanceControllerProvider);
      expect(initialDebts.length, equals(3));

      final bottomDebt = initialDebts.last;
      notifier.reorder(2, 0);

      final reordered = container.read(clearanceControllerProvider);
      expect(reordered.first.id, equals(bottomDebt.id));
      expect(reordered.length, equals(3));
      expect(reordered[1].creditor, equals('Card A'));
      expect(reordered[2].creditor, equals('Card B'));
    });

    test('ClearanceController moves top item to bottom', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Loan 1', totalOwed: 1000);
      notifier.addDebt(creditor: 'Loan 2', totalOwed: 2000);
      notifier.addDebt(creditor: 'Loan 3', totalOwed: 3000);

      final initialDebts = container.read(clearanceControllerProvider);
      final topDebt = initialDebts.first;

      notifier.reorder(0, 2);

      final reordered = container.read(clearanceControllerProvider);
      expect(reordered.last.id, equals(topDebt.id));
      expect(reordered[0].creditor, equals('Loan 2'));
      expect(reordered[1].creditor, equals('Loan 3'));
    });

    test('ClearanceController ignores out-of-bound indices', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      notifier.addDebt(creditor: 'Test Debt', totalOwed: 500);

      final initialDebts = container.read(clearanceControllerProvider);

      notifier.reorder(-1, 0);
      notifier.reorder(0, 999);
      notifier.reorder(0, 0);

      final current = container.read(clearanceControllerProvider);
      expect(current.map((d) => d.id), equals(initialDebts.map((d) => d.id)));
    });

    test('MilestonesController moves bottom milestone to top', () {
      final notifier = container.read(milestonesControllerProvider.notifier);
      notifier.addMilestone(title: 'Emergency Fund', targetAmount: 5000);
      notifier.addMilestone(title: 'Vacation', targetAmount: 2000);
      notifier.addMilestone(title: 'New Laptop', targetAmount: 2500);

      final initialMilestones = container.read(milestonesControllerProvider);
      expect(initialMilestones.length, equals(3));

      final bottomMilestone = initialMilestones.last;
      notifier.reorder(2, 0);

      final reordered = container.read(milestonesControllerProvider);
      expect(reordered.first.id, equals(bottomMilestone.id));
      expect(reordered[1].title, equals('Emergency Fund'));
      expect(reordered[2].title, equals('Vacation'));
    });

    test('AssetsController moves bottom asset to top', () {
      final notifier = container.read(assetsControllerProvider.notifier);
      notifier.addAsset(title: 'Index Fund', targetAmount: 50000);
      notifier.addAsset(title: 'Real Estate', targetAmount: 150000);
      notifier.addAsset(title: 'Tech Equity', targetAmount: 80000);

      final initialAssets = container.read(assetsControllerProvider);
      expect(initialAssets.length, equals(3));

      final bottomAsset = initialAssets.last;
      notifier.reorder(2, 0);

      final reordered = container.read(assetsControllerProvider);
      expect(reordered.first.id, equals(bottomAsset.id));
      expect(reordered[1].title, equals('Index Fund'));
      expect(reordered[2].title, equals('Real Estate'));
    });

    test('ClearanceController preserves optional dueDate and allows updating it', () {
      final notifier = container.read(clearanceControllerProvider.notifier);
      final dueDate = DateTime.now().add(const Duration(days: 5));
      notifier.addDebt(
        creditor: 'Due Card',
        totalOwed: 5000,
        dueDate: dueDate,
      );

      final debts = container.read(clearanceControllerProvider);
      final debt = debts.firstWhere((d) => d.creditor == 'Due Card');
      expect(debt.hasDueDate, isTrue);
      expect(debt.isDueSoon, isTrue);
      expect(debt.isOverdue, isFalse);

      final newDueDate = DateTime.now().subtract(const Duration(days: 2));
      notifier.updateDueDate(debt.id, newDueDate);

      final updatedDebts = container.read(clearanceControllerProvider);
      final updatedDebt = updatedDebts.firstWhere((d) => d.id == debt.id);
      expect(updatedDebt.isOverdue, isTrue);
      expect(updatedDebt.isDueSoon, isFalse);

      // Clear due date
      notifier.updateDueDate(debt.id, null);
      final clearedDebt = container.read(clearanceControllerProvider).firstWhere((d) => d.id == debt.id);
      expect(clearedDebt.hasDueDate, isFalse);
    });
  });
}
