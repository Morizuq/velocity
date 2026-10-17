import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debt_entity.dart';

/// State notifier managing clearance debts, payments, and burn-down progression.
class ClearanceController extends Notifier<List<DebtEntity>> {
  @override
  List<DebtEntity> build() {
    // Initial seeded baseline representing debts outlined in project scope
    return const [
      DebtEntity(
        id: 'debt_kuda',
        creditor: 'Kuda',
        totalOwed: 100000,
        amountPaid: 45000,
        isCleared: false,
      ),
      DebtEntity(
        id: 'debt_palmpay',
        creditor: 'Palmpay',
        totalOwed: 50000,
        amountPaid: 20000,
        isCleared: false,
      ),
      DebtEntity(
        id: 'debt_justin',
        creditor: 'Justin',
        totalOwed: 80000,
        amountPaid: 30000,
        isCleared: false,
      ),
      DebtEntity(
        id: 'debt_mom',
        creditor: 'Mom',
        totalOwed: 150000,
        amountPaid: 150000,
        isCleared: true,
      ),
    ];
  }

  /// Deducts an incoming payment from the target debt.
  void logPayment(String debtId, double paymentAmount) {
    state = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            amountPaid: (debt.amountPaid + paymentAmount).clamp(0.0, debt.totalOwed),
          )
        else
          debt,
    ];
  }

  /// Appends a new debt to the clearance bucket.
  void addDebt({required String creditor, required double totalOwed}) {
    final newDebt = DebtEntity(
      id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
      creditor: creditor,
      totalOwed: totalOwed,
      amountPaid: 0.0,
      isCleared: false,
    );
    state = [...state, newDebt];
  }

  /// Toggles clearance status directly.
  void toggleCleared(String debtId) {
    state = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            isCleared: !debt.isCleared,
            amountPaid: !debt.isCleared ? debt.totalOwed : debt.amountPaid,
          )
        else
          debt,
    ];
  }
}

final clearanceControllerProvider =
    NotifierProvider<ClearanceController, List<DebtEntity>>(
  ClearanceController.new,
);

/// Provider computing total remaining unpaid clearance debt across all active accounts.
final totalClearanceDebtProvider = Provider<double>((ref) {
  final debts = ref.watch(clearanceControllerProvider);
  return debts.where((d) => !d.isCleared).fold<double>(
        0.0,
        (sum, debt) => sum + debt.remainingAmount,
      );
});

/// Provider computing total original debt balance.
final totalOriginalDebtProvider = Provider<double>((ref) {
  final debts = ref.watch(clearanceControllerProvider);
  return debts.fold<double>(0.0, (sum, debt) => sum + debt.totalOwed);
});

/// Provider computing total debt paid so far.
final totalDebtPaidProvider = Provider<double>((ref) {
  final debts = ref.watch(clearanceControllerProvider);
  return debts.fold<double>(0.0, (sum, debt) => sum + debt.amountPaid);
});
