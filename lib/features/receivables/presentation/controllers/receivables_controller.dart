import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/receivable_entity.dart';
import '../../domain/entities/receivable_type.dart';

/// State notifier managing receivables (freelance invoices, personal loans, reimbursements),
/// local database caching, and live cloud synchronization across devices.
class ReceivablesController extends Notifier<List<ReceivableEntity>> {
  static const _storageKey = 'velocity_receivables';
  StreamSubscription<List<ReceivableEntity>>? _firestoreSub;
  String? _currentUid;

  @override
  List<ReceivableEntity> build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localReceivables = _loadLocal();

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

    return localReceivables;
  }

  List<ReceivableEntity> _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => ReceivableEntity.fromMap(e as Map<String, dynamic>))
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
      syncService.syncReceivables(uid, state);
    }

    _firestoreSub = syncService.watchReceivables(uid).listen((remoteItems) {
      if (remoteItems.isNotEmpty || state.isEmpty) {
        state = remoteItems;
        _persist(remoteItems, pushToCloud: false);
      }
    });
  }

  void _persist(List<ReceivableEntity> updated, {bool pushToCloud = true}) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref
          .read(firestoreSyncServiceProvider)
          .syncReceivables(_currentUid!, updated);
    }
  }

  /// Records an incoming payment against a receivable.
  void logPayment(String id, double paymentAmount) {
    final updated = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            amountReceived: (item.amountReceived + paymentAmount).clamp(
              0.0,
              item.totalAmount,
            ),
          )
        else
          item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Alias for logPayment.
  void recordPayment(String id, double paymentAmount) =>
      logPayment(id, paymentAmount);

  /// Appends a new receivable claim to the user's ledger.
  void addReceivable({
    required String debtor,
    required double totalAmount,
    double initialReceived = 0.0,
    required ReceivableType type,
    DateTime? dueDate,
    String? description,
    String? invoiceNumber,
    String? notes,
  }) {
    final newItem = ReceivableEntity(
      id: 'recv_${DateTime.now().microsecondsSinceEpoch}_${state.length}',
      debtor: debtor.trim(),
      totalAmount: totalAmount,
      amountReceived: initialReceived,
      type: type,
      issueDate: DateTime.now(),
      dueDate: dueDate,
      description: description?.trim().isNotEmpty == true
          ? description!.trim()
          : null,
      invoiceNumber: invoiceNumber?.trim().isNotEmpty == true
          ? invoiceNumber!.trim()
          : null,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
    );
    final updated = [...state, newItem];
    state = updated;
    _persist(updated);
  }

  /// Updates an existing receivable entity.
  void updateReceivable(ReceivableEntity updatedEntity) {
    final updated = [
      for (final item in state)
        if (item.id == updatedEntity.id) updatedEntity else item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Toggles the settled status of a receivable.
  /// When un-settling, resets amountReceived to 0.0 so remaining balance is restored.
  void toggleSettled(String id) {
    final updated = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            isSettled: !item.isSettled,
            amountReceived: !item.isSettled ? item.totalAmount : 0.0,
          )
        else
          item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Restores a settled receivable back to active status.
  void undoSettled(String id, [double newAmountReceived = 0.0]) {
    final updated = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            isSettled: false,
            amountReceived: newAmountReceived.clamp(0.0, item.totalAmount),
          )
        else
          item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Updates debtor, total amount, amount received, or due date of an existing receivable.
  void editReceivable({
    required String id,
    String? debtor,
    double? totalAmount,
    double? amountReceived,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    final updated = [
      for (final item in state)
        if (item.id == id)
          () {
            final newTotal = totalAmount ?? item.totalAmount;
            final newReceived = amountReceived ?? item.amountReceived;
            final isSettled = newReceived >= newTotal && newTotal > 0;
            return item.copyWith(
              debtor: debtor ?? item.debtor,
              totalAmount: newTotal,
              amountReceived: newReceived.clamp(0.0, newTotal),
              isSettled: isSettled,
              dueDate: clearDueDate ? null : (dueDate ?? item.dueDate),
            );
          }()
        else
          item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Permanently removes a receivable.
  void deleteReceivable(String id) {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    _persist(updated, pushToCloud: false);

    if (_currentUid != null) {
      ref.read(firestoreSyncServiceProvider).deleteReceivable(_currentUid!, id);
    }
  }

  /// Restores a deleted receivable item (for Undo toast).
  void restoreReceivable(ReceivableEntity item, int targetIndex) {
    final list = List<ReceivableEntity>.from(state);
    final insertIdx = targetIndex.clamp(0, list.length);
    list.insert(insertIdx, item);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  /// Reorders items for tactical priority layout.
  void reorderReceivables(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.length ||
        newIndex < 0 ||
        newIndex > state.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<ReceivableEntity>.from(state);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    final renumbered = _renumber(items);
    state = renumbered;
    _persist(renumbered);
  }

  /// Accessibility move buttons ('top', 'up', 'down').
  void move(int index, String direction) {
    if (index < 0 || index >= state.length) return;
    final list = List<ReceivableEntity>.from(state);
    final item = list.removeAt(index);
    int target = index;
    if (direction == 'top') {
      target = 0;
    } else if (direction == 'up') {
      target = (index - 1).clamp(0, list.length);
    } else if (direction == 'down') {
      target = (index + 1).clamp(0, list.length);
    }
    list.insert(target, item);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  List<ReceivableEntity> _renumber(List<ReceivableEntity> list) {
    return [
      for (int i = 0; i < list.length; i++) list[i].copyWith(sortIndex: i),
    ];
  }

  /// Clears all receivables entities.
  void clearAll() {
    state = const [];
    _persist(const []);
  }
}

/// Provider exposing the list of receivables.
final receivablesControllerProvider =
    NotifierProvider<ReceivablesController, List<ReceivableEntity>>(
      ReceivablesController.new,
    );

/// Aggregates total outstanding receivables awaiting collection.
final totalReceivablesProvider = Provider<double>((ref) {
  final items = ref.watch(receivablesControllerProvider);
  return items.where((r) => !r.isSettled).fold<double>(
    0.0,
    (acc, curr) => acc + curr.remainingBalance,
  );
});

/// Aggregates total funds collected from receivables.
final totalReceivedProvider = Provider<double>((ref) {
  final items = ref.watch(receivablesControllerProvider);
  return items.fold<double>(0.0, (acc, curr) => acc + curr.amountReceived);
});

/// Aggregates total original face value of all receivables.
final totalOriginalReceivablesProvider = Provider<double>((ref) {
  final items = ref.watch(receivablesControllerProvider);
  return items.fold<double>(0.0, (acc, curr) => acc + curr.totalAmount);
});
