import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity/core/storage/shared_prefs_storage.dart';
import 'package:velocity/features/receivables/domain/entities/receivable_entity.dart';
import 'package:velocity/features/receivables/domain/entities/receivable_type.dart';
import 'package:velocity/features/receivables/presentation/controllers/receivables_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceivableEntity Domain Unit Tests', () {
    test('computes remaining balance and progress ratio accurately', () {
      final claim = ReceivableEntity(
        id: '1',
        debtor: 'Client Studio',
        totalAmount: 1000.0,
        amountReceived: 250.0,
        type: ReceivableType.freelanceInvoice,
        issueDate: DateTime(2026, 1, 1),
      );

      expect(claim.remainingBalance, equals(750.0));
      expect(claim.collectionProgress, equals(0.25));
      expect(claim.progressPercentage, equals(25));
      expect(claim.isSettled, isFalse);
    });

    test('detects overdue status when past due date and unsettled', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final overdueClaim = ReceivableEntity(
        id: '2',
        debtor: 'John Doe',
        totalAmount: 300.0,
        amountReceived: 0.0,
        type: ReceivableType.personalLoan,
        issueDate: DateTime(2026, 1, 1),
        dueDate: pastDate,
      );

      expect(overdueClaim.isOverdue, isTrue);
      expect(overdueClaim.isDueSoon, isFalse);
    });

    test('detects due soon status within 7 days', () {
      final soonDate = DateTime.now().add(const Duration(days: 4));
      final soonClaim = ReceivableEntity(
        id: '3',
        debtor: 'Friend',
        totalAmount: 150.0,
        amountReceived: 0.0,
        type: ReceivableType.reimbursement,
        issueDate: DateTime.now(),
        dueDate: soonDate,
      );

      expect(soonClaim.isDueSoon, isTrue);
      expect(soonClaim.isOverdue, isFalse);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final claim = ReceivableEntity(
        id: '4',
        debtor: 'Design Agency',
        description: 'Brand identity & design systems sprint',
        totalAmount: 2500.0,
        amountReceived: 500.0,
        type: ReceivableType.freelanceInvoice,
        issueDate: DateTime(2026, 2, 1),
        dueDate: DateTime(2026, 3, 1),
        invoiceNumber: 'INV-101',
        notes: 'UI overhaul retainer',
      );

      final map = claim.toMap();
      final reconstructed = ReceivableEntity.fromMap(map);

      expect(reconstructed.id, equals(claim.id));
      expect(reconstructed.debtor, equals(claim.debtor));
      expect(
        reconstructed.description,
        equals('Brand identity & design systems sprint'),
      );
      expect(reconstructed.totalAmount, equals(claim.totalAmount));
      expect(reconstructed.amountReceived, equals(claim.amountReceived));
      expect(reconstructed.type, equals(ReceivableType.freelanceInvoice));
      expect(reconstructed.invoiceNumber, equals('INV-101'));
      expect(reconstructed.notes, equals('UI overhaul retainer'));
    });
  });

  group('ReceivablesController State Management Tests', () {
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

    test('adds receivable and calculates total outstanding metrics', () {
      final notifier = container.read(receivablesControllerProvider.notifier);

      notifier.addReceivable(
        debtor: 'Company Alpha',
        totalAmount: 1200.0,
        initialReceived: 200.0,
        type: ReceivableType.freelanceInvoice,
        invoiceNumber: 'INV-2026-01',
      );

      notifier.addReceivable(
        debtor: 'Sam Smith',
        totalAmount: 300.0,
        initialReceived: 0.0,
        type: ReceivableType.personalLoan,
      );

      final items = container.read(receivablesControllerProvider);
      expect(items.length, equals(2));

      // 1000 remaining on Alpha + 300 remaining on Sam = 1300
      final totalOutstanding = container.read(totalReceivablesProvider);
      expect(totalOutstanding, equals(1300.0));

      // 200 received
      final totalReceived = container.read(totalReceivedProvider);
      expect(totalReceived, equals(200.0));
    });

    test('logs incoming payments and auto-settles when full balance reached', () {
      final notifier = container.read(receivablesControllerProvider.notifier);

      notifier.addReceivable(
        debtor: 'Beta LLC',
        totalAmount: 500.0,
        type: ReceivableType.freelanceInvoice,
      );

      final initial = container.read(receivablesControllerProvider).first;
      notifier.logPayment(initial.id, 200.0);

      var updated = container.read(receivablesControllerProvider).first;
      expect(updated.amountReceived, equals(200.0));
      expect(updated.remainingBalance, equals(300.0));
      expect(updated.isSettled, isFalse);

      // Pay remaining 300
      notifier.logPayment(initial.id, 300.0);
      updated = container.read(receivablesControllerProvider).first;
      expect(updated.amountReceived, equals(500.0));
      expect(updated.remainingBalance, equals(0.0));
      expect(updated.isSettled, isTrue);
    });

    test('toggles settled status manually', () {
      final notifier = container.read(receivablesControllerProvider.notifier);

      notifier.addReceivable(
        debtor: 'Colleague',
        totalAmount: 100.0,
        type: ReceivableType.reimbursement,
      );

      final item = container.read(receivablesControllerProvider).first;
      expect(item.isSettled, isFalse);

      notifier.toggleSettled(item.id);
      final settled = container.read(receivablesControllerProvider).first;
      expect(settled.isSettled, isTrue);
      expect(settled.amountReceived, equals(100.0));
    });

    test('reorders items properly', () {
      final notifier = container.read(receivablesControllerProvider.notifier);

      notifier.addReceivable(
        debtor: 'Claim 1',
        totalAmount: 100.0,
        type: ReceivableType.personalLoan,
      );
      notifier.addReceivable(
        debtor: 'Claim 2',
        totalAmount: 200.0,
        type: ReceivableType.personalLoan,
      );
      notifier.addReceivable(
        debtor: 'Claim 3',
        totalAmount: 300.0,
        type: ReceivableType.personalLoan,
      );

      notifier.reorderReceivables(2, 0);

      final reordered = container.read(receivablesControllerProvider);
      expect(reordered.first.debtor, equals('Claim 3'));
      expect(reordered[1].debtor, equals('Claim 1'));
      expect(reordered[2].debtor, equals('Claim 2'));
    });

    test('deletes receivable correctly', () {
      final notifier = container.read(receivablesControllerProvider.notifier);

      notifier.addReceivable(
        debtor: 'Discardable Claim',
        totalAmount: 50.0,
        type: ReceivableType.personalLoan,
      );

      final item = container.read(receivablesControllerProvider).first;
      notifier.deleteReceivable(item.id);

      final remaining = container.read(receivablesControllerProvider);
      expect(remaining.isEmpty, isTrue);
    });
  });
}
