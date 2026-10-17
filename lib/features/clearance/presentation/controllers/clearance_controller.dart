import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../domain/entities/debt_entity.dart';

/// State notifier managing clearance debts, payments, and local database persistence.
class ClearanceController extends Notifier<List<DebtEntity>> {
  static const _storageKey = 'velocity_clearance_debts';

  @override
  List<DebtEntity> build() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => DebtEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  void _persist(List<DebtEntity> updated) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((d) => d.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}
  }

  /// Deducts an incoming payment from the target debt.
  void logPayment(String debtId, double paymentAmount) {
    final updated = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            amountPaid: (debt.amountPaid + paymentAmount).clamp(
              0.0,
              debt.totalOwed,
            ),
          )
        else
          debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Appends a new debt to the clearance bucket.
  void addDebt({
    required String creditor,
    required double totalOwed,
    double initialPaid = 0.0,
  }) {
    final newDebt = DebtEntity(
      id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
      creditor: creditor,
      totalOwed: totalOwed,
      amountPaid: initialPaid,
      isCleared: initialPaid >= totalOwed && totalOwed > 0,
    );
    final updated = [...state, newDebt];
    state = updated;
    _persist(updated);
  }

  /// Toggles clearance status directly.
  void toggleCleared(String debtId) {
    final updated = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            isCleared: !debt.isCleared,
            amountPaid: !debt.isCleared ? debt.totalOwed : debt.amountPaid,
          )
        else
          debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Deletes a debt item from local storage.
  void deleteDebt(String debtId) {
    final updated = state.where((d) => d.id != debtId).toList();
    state = updated;
    _persist(updated);
  }
}

final clearanceControllerProvider =
    NotifierProvider<ClearanceController, List<DebtEntity>>(
      ClearanceController.new,
    );

/// Provider computing total remaining unpaid clearance debt across all active accounts.
final totalClearanceDebtProvider = Provider<double>((ref) {
  final debts = ref.watch(clearanceControllerProvider);
  return debts
      .where((d) => !d.isCleared)
      .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);
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
