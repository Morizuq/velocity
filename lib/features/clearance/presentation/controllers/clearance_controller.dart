import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/debt_entity.dart';

/// State notifier managing clearance debts, payments, local database persistence,
/// and live cloud synchronization across devices.
class ClearanceController extends Notifier<List<DebtEntity>> {
  static const _storageKey = 'velocity_clearance_debts';
  StreamSubscription<List<DebtEntity>>? _firestoreSub;
  String? _currentUid;

  @override
  List<DebtEntity> build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localDebts = _loadLocal();

    // Listen for auth state transitions (sign in, sign out, switch account)
    ref.listen<AsyncValue<UserEntity?>>(authStateChangesProvider, (prev, next) {
      final user = next.asData?.value;
      if (user?.id != _currentUid) {
        _currentUid = user?.id;
        _onAuthChanged(user?.id);
      }
    });

    final initialUser = ref.read(authStateChangesProvider).asData?.value;
    _currentUid = initialUser?.id;
    if (_currentUid != null) {
      Future.microtask(() => _onAuthChanged(_currentUid));
    }

    return localDebts;
  }

  List<DebtEntity> _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded
            .map((e) => DebtEntity.fromMap(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
        return list;
      }
    } catch (_) {}
    return const [];
  }

  void _onAuthChanged(String? uid) {
    _firestoreSub?.cancel();
    _firestoreSub = null;

    if (uid == null) return;

    final syncService = ref.read(firestoreSyncServiceProvider);

    if (state.isNotEmpty) {
      syncService.syncDebts(uid, state);
    }

    _firestoreSub = syncService.watchDebts(uid).listen((remoteDebts) {
      if (remoteDebts.isNotEmpty || state.isEmpty) {
        final sorted = List<DebtEntity>.from(remoteDebts)
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
        state = sorted;
        _persist(sorted, pushToCloud: false);
      }
    });
  }

  void _persist(List<DebtEntity> updated, {bool pushToCloud = true}) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((d) => d.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref.read(firestoreSyncServiceProvider).syncDebts(_currentUid!, updated);
    }
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

  /// Toggles whether a debt is marked as fully cleared.
  /// When un-clearing, resets amountPaid to 0.0 so remaining balance is restored.
  void toggleCleared(String debtId) {
    final updated = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            isCleared: !debt.isCleared,
            amountPaid: !debt.isCleared ? debt.totalOwed : 0.0,
          )
        else
          debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Restores a cleared debt back to active status with an optional custom paid balance.
  void undoCleared(String debtId, [double newAmountPaid = 0.0]) {
    final updated = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(
            isCleared: false,
            amountPaid: newAmountPaid.clamp(0.0, debt.totalOwed),
          )
        else
          debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Updates creditor, total owed, amount paid, monthly payment, or due date of an existing debt.
  void editDebt({
    required String debtId,
    String? creditor,
    double? totalOwed,
    double? amountPaid,
    double? monthlyPayment,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    final updated = [
      for (final d in state)
        if (d.id == debtId)
          () {
            final newTotal = totalOwed ?? d.totalOwed;
            final newPaid = amountPaid ?? d.amountPaid;
            final isCleared = newPaid >= newTotal && newTotal > 0;
            return d.copyWith(
              creditor: creditor ?? d.creditor,
              totalOwed: newTotal,
              amountPaid: newPaid.clamp(0.0, newTotal),
              monthlyPayment: monthlyPayment ?? d.monthlyPayment,
              isCleared: isCleared,
              dueDate: clearDueDate ? null : (dueDate ?? d.dueDate),
            );
          }()
        else
          d,
    ];
    state = updated;
    _persist(updated);
  }

  /// Appends a new debt to the debts bucket.
  void addDebt({
    required String creditor,
    required double totalOwed,
    double initialPaid = 0.0,
    double monthlyPayment = 0.0,
    DateTime? dueDate,
  }) {
    final newDebt = DebtEntity(
      id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
      creditor: creditor,
      totalOwed: totalOwed,
      amountPaid: initialPaid,
      monthlyPayment: monthlyPayment,
      isCleared: initialPaid >= totalOwed && totalOwed > 0,
      dueDate: dueDate,
      sortIndex: state.length,
    );
    final updated = [...state, newDebt];
    state = updated;
    _persist(updated);
  }

  /// Updates an existing debt entity.
  void updateDebt(DebtEntity updatedEntity) {
    final updated = [
      for (final debt in state)
        if (debt.id == updatedEntity.id) updatedEntity else debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Restores a deleted debt item (e.g. via Undo toast).
  void restoreDebt(DebtEntity debt, int targetIndex) {
    final list = List<DebtEntity>.from(state);
    final insertIdx = targetIndex.clamp(0, list.length);
    list.insert(insertIdx, debt);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  /// Updates or clears the due date for an existing debt.
  void updateDueDate(String debtId, DateTime? dueDate) {
    final updated = [
      for (final debt in state)
        if (debt.id == debtId)
          debt.copyWith(dueDate: dueDate, clearDueDate: dueDate == null)
        else
          debt,
    ];
    state = updated;
    _persist(updated);
  }

  /// Deletes a debt item from local storage and Cloud Firestore.
  void deleteDebt(String debtId) {
    final list = state.where((d) => d.id != debtId).toList();
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered, pushToCloud: false);
    if (_currentUid != null) {
      ref.read(firestoreSyncServiceProvider).deleteDebt(_currentUid!, debtId);
    }
  }

  /// Reorders debts when dragged and dropped, renumbering sortIndex.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;
    if (oldIndex == newIndex) return;
    final updated = List<DebtEntity>.from(state);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    final renumbered = _renumber(updated);
    state = renumbered;
    _persist(renumbered);
  }

  /// Accessibility move button support ('top', 'up', 'down').
  void move(int index, String direction) {
    if (index < 0 || index >= state.length) return;
    final list = List<DebtEntity>.from(state);
    final item = list.removeAt(index);
    int target = index;
    if (direction == 'top') {
      target = 0;
    } else if (direction == 'up') {
      target = math.max(0, index - 1);
    } else if (direction == 'down') {
      target = math.min(list.length, index + 1);
    }
    list.insert(target, item);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  List<DebtEntity> _renumber(List<DebtEntity> list) {
    return [
      for (int i = 0; i < list.length; i++) list[i].copyWith(sortIndex: i),
    ];
  }

  /// Clears all debts (e.g. on reset or deployment purge).
  void clearAll() {
    state = const [];
    _persist(const []);
  }
}

final clearanceControllerProvider =
    NotifierProvider<ClearanceController, List<DebtEntity>>(
      ClearanceController.new,
    );

/// Provider computing total remaining unpaid debt across active accounts.
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

/// Provider computing total monthly debt commitments going out each month.
final totalDebtMonthlyPaymentProvider = Provider<double>((ref) {
  final debts = ref.watch(clearanceControllerProvider);
  return debts
      .where((d) => d.totalOwed > d.amountPaid)
      .fold<double>(0.0, (sum, d) {
        final left = d.totalOwed - d.amountPaid;
        final pay = d.monthlyPayment > 0 ? math.min(d.monthlyPayment, left) : 0.0;
        return sum + pay;
      });
});
