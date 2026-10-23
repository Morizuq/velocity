import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/cashflow_direction.dart';
import '../../domain/entities/recurring_cashflow_entity.dart';

/// State notifier managing recurring monthly payables (subscriptions, utilities, bills)
/// and recurring monthly inflows (salary, retainers, stipends).
class RecurringCashflowController
    extends Notifier<List<RecurringCashflowEntity>> {
  static const _storageKey = 'velocity_recurring_cashflows';
  StreamSubscription<List<RecurringCashflowEntity>>? _firestoreSub;
  String? _currentUid;

  @override
  List<RecurringCashflowEntity> build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localItems = _loadLocal();

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

    return localItems;
  }

  List<RecurringCashflowEntity> _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map(
              (e) => RecurringCashflowEntity.fromMap(e as Map<String, dynamic>),
            )
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
      syncService.syncRecurringCashflows(uid, state);
    }

    _firestoreSub = syncService.watchRecurringCashflows(uid).listen((remote) {
      if (remote.isNotEmpty || state.isEmpty) {
        state = remote;
        _persist(remote, pushToCloud: false);
      }
    });
  }

  void _persist(
    List<RecurringCashflowEntity> updated, {
    bool pushToCloud = true,
  }) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref
          .read(firestoreSyncServiceProvider)
          .syncRecurringCashflows(_currentUid!, updated);
    }
  }

  /// Appends a new recurring cash flow commitment.
  void addCashflow({
    required String title,
    required double amount,
    required CashflowDirection direction,
    required int dayOfMonth,
    String category = 'General',
    DateTime? endDate,
    String? notes,
  }) {
    final newItem = RecurringCashflowEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: amount,
      direction: direction,
      dayOfMonth: dayOfMonth,
      category: category.trim().isNotEmpty ? category.trim() : 'General',
      endDate: endDate,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
    );
    final updated = [...state, newItem];
    state = updated;
    _persist(updated);
  }

  /// Updates an existing cash flow record.
  void updateCashflow(RecurringCashflowEntity updatedEntity) {
    final updated = [
      for (final item in state)
        if (item.id == updatedEntity.id) updatedEntity else item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Toggles the settled status for the active calendar month.
  void toggleSettledCurrentCycle(String id) {
    final updated = [
      for (final item in state)
        if (item.id == id)
          item.isSettledThisMonth
              ? item.unmarkSettled()
              : item.markSettledForCurrentCycle()
        else
          item,
    ];
    state = updated;
    _persist(updated);
  }

  /// Permanently removes a recurring item.
  void deleteCashflow(String id) {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    _persist(updated, pushToCloud: false);

    if (_currentUid != null) {
      ref
          .read(firestoreSyncServiceProvider)
          .deleteRecurringCashflow(_currentUid!, id);
    }
  }

  /// Moves an item within its directional group (Income or Expense) by button.
  void moveWithinDirection(
    String id,
    CashflowDirection direction,
    String moveDirection,
  ) {
    final group = state.where((i) => i.direction == direction).toList();
    group.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final index = group.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = group.removeAt(index);
    int target;
    if (moveDirection == 'top') {
      target = 0;
    } else if (moveDirection == 'up') {
      target = (index - 1).clamp(0, group.length);
    } else {
      target = (index + 1).clamp(0, group.length);
    }
    group.insert(target, item);

    final renumberedGroup = [
      for (int i = 0; i < group.length; i++) group[i].copyWith(sortIndex: i),
    ];
    final otherGroup = state.where((i) => i.direction != direction).toList();
    final updated = [...otherGroup, ...renumberedGroup];
    state = updated;
    _persist(updated);
  }

  /// Reorders items within a directional group (Income or Expense) via drag.
  void reorderWithinDirection(
    CashflowDirection direction,
    int oldIndex,
    int newIndex,
  ) {
    final group = state.where((i) => i.direction == direction).toList();
    group.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    if (oldIndex < 0 ||
        oldIndex >= group.length ||
        newIndex < 0 ||
        newIndex > group.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = group.removeAt(oldIndex);
    group.insert(newIndex, item);

    final renumberedGroup = [
      for (int i = 0; i < group.length; i++) group[i].copyWith(sortIndex: i),
    ];
    final otherGroup = state.where((i) => i.direction != direction).toList();
    final updated = [...otherGroup, ...renumberedGroup];
    state = updated;
    _persist(updated);
  }

  /// Restores a deleted item (e.g. for Undo toast).
  void restoreCashflow(RecurringCashflowEntity item, [int? index]) {
    final list = List<RecurringCashflowEntity>.from(state);
    if (index != null && index >= 0 && index <= list.length) {
      list.insert(index, item);
    } else {
      list.add(item);
    }
    state = list;
    _persist(list);
  }

  /// Reorders items in priority sequence.
  void reorderCashflows(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.length ||
        newIndex < 0 ||
        newIndex > state.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<RecurringCashflowEntity>.from(state);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    state = items;
    _persist(items);
  }

  /// Clears all recurring cashflow entities.
  void clearAll() {
    state = const [];
    _persist(const []);
  }
}

/// Provider exposing the complete list of recurring cash flows.
final recurringCashflowControllerProvider =
    NotifierProvider<
      RecurringCashflowController,
      List<RecurringCashflowEntity>
    >(RecurringCashflowController.new);

/// List of all monthly recurring outgoings (Internet, Spotify, Rent, Utilities).
final monthlyOutflowsProvider = Provider<List<RecurringCashflowEntity>>((ref) {
  final items = ref.watch(recurringCashflowControllerProvider);
  final outflows =
      items
          .where((i) => i.direction == CashflowDirection.outflowPayable)
          .toList();
  outflows.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  return outflows;
});

/// List of all monthly recurring incomings (Salary, Client Retainers).
final monthlyInflowsProvider = Provider<List<RecurringCashflowEntity>>((ref) {
  final items = ref.watch(recurringCashflowControllerProvider);
  final inflows =
      items
          .where((i) => i.direction == CashflowDirection.inflowReceivable)
          .toList();
  inflows.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  return inflows;
});

/// Total monthly recurring outflow commitments (Burn Rate).
final monthlyOutflowTotalProvider = Provider<double>((ref) {
  final outflows = ref.watch(monthlyOutflowsProvider);
  return outflows.fold<double>(0.0, (acc, curr) => acc + curr.amount);
});

/// Total fixed monthly incoming revenue (Guaranteed Income).
final monthlyInflowTotalProvider = Provider<double>((ref) {
  final inflows = ref.watch(monthlyInflowsProvider);
  return inflows.fold<double>(0.0, (acc, curr) => acc + curr.amount);
});

/// Net monthly operating cash flow (Inflows - Outflows).
final netMonthlyCashflowProvider = Provider<double>((ref) {
  final inflows = ref.watch(monthlyInflowTotalProvider);
  final outflows = ref.watch(monthlyOutflowTotalProvider);
  return inflows - outflows;
});

/// Total pending outflows not yet marked paid for the active month.
final pendingOutflowThisMonthProvider = Provider<double>((ref) {
  final outflows = ref.watch(monthlyOutflowsProvider);
  return outflows
      .where((i) => !i.isSettledThisMonth)
      .fold<double>(0.0, (acc, curr) => acc + curr.amount);
});

/// Total pending inflows not yet marked received for the active month.
final pendingInflowThisMonthProvider = Provider<double>((ref) {
  final inflows = ref.watch(monthlyInflowsProvider);
  return inflows
      .where((i) => !i.isSettledThisMonth)
      .fold<double>(0.0, (acc, curr) => acc + curr.amount);
});

/// Computes liquid cash runway in months.
final cashRunwayMonthsProvider = Provider<double>((ref) {
  final liquidCash = ref.watch(dashboardControllerProvider);
  final monthlyOutflow = ref.watch(monthlyOutflowTotalProvider);
  final monthlyInflow = ref.watch(monthlyInflowTotalProvider);

  final netBurn = monthlyOutflow - monthlyInflow;
  if (netBurn <= 0) {
    return double.infinity; // Cash positive
  }
  if (liquidCash <= 0) {
    return 0.0;
  }
  return liquidCash / netBurn;
});
