import 'dart:async';
import 'dart:convert';
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
        return decoded
            .map((e) => DebtEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  void _onAuthChanged(String? uid) {
    _firestoreSub?.cancel();
    _firestoreSub = null;

    if (uid == null) return;

    final syncService = ref.read(firestoreSyncServiceProvider);

    // If local state had items created before login, seed remote collection
    if (state.isNotEmpty) {
      syncService.syncDebts(uid, state);
    }

    _firestoreSub = syncService.watchDebts(uid).listen((remoteDebts) {
      if (remoteDebts.isNotEmpty || state.isEmpty) {
        state = remoteDebts;
        _persist(remoteDebts, pushToCloud: false);
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

  /// Appends a new debt to the clearance bucket.
  void addDebt({
    required String creditor,
    required double totalOwed,
    double initialPaid = 0.0,
    DateTime? dueDate,
  }) {
    final newDebt = DebtEntity(
      id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
      creditor: creditor,
      totalOwed: totalOwed,
      amountPaid: initialPaid,
      isCleared: initialPaid >= totalOwed && totalOwed > 0,
      dueDate: dueDate,
    );
    final updated = [...state, newDebt];
    state = updated;
    _persist(updated);
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

  /// Deletes a debt item from local storage and Cloud Firestore.
  void deleteDebt(String debtId) {
    final updated = state.where((d) => d.id != debtId).toList();
    state = updated;
    _persist(updated, pushToCloud: false);
    if (_currentUid != null) {
      ref.read(firestoreSyncServiceProvider).deleteDebt(_currentUid!, debtId);
    }
  }

  /// Reorders debts when dragged and dropped, updating local and cloud sequence.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;
    if (oldIndex == newIndex) return;
    final updated = List<DebtEntity>.from(state);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
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
