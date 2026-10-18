import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// State notifier managing high-level liquid cash balance with local persistence
/// and live cloud synchronization across devices.
class DashboardController extends Notifier<double> {
  static const _storageKey = 'velocity_liquid_cash';
  StreamSubscription<double?>? _firestoreSub;
  String? _currentUid;

  @override
  double build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localCash = _loadLocal();

    // Listen for auth state transitions
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

    return localCash;
  }

  double _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final savedCash = storage.getString(_storageKey);
      if (savedCash != null && savedCash.isNotEmpty) {
        final parsed = double.tryParse(savedCash);
        if (parsed != null) return parsed;
      }
    } catch (_) {}
    return 0.0;
  }

  void _onAuthChanged(String? uid) {
    _firestoreSub?.cancel();
    _firestoreSub = null;

    if (uid == null) return;

    final syncService = ref.read(firestoreSyncServiceProvider);

    if (state > 0) {
      syncService.syncLiquidCash(uid, state);
    }

    _firestoreSub = syncService.watchLiquidCash(uid).listen((remoteCash) {
      if (remoteCash != null) {
        state = remoteCash;
        _persist(remoteCash, pushToCloud: false);
      }
    });
  }

  void _persist(double amount, {bool pushToCloud = true}) {
    try {
      final storage = ref.read(storageServiceProvider);
      storage.setString(_storageKey, amount.toString());
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref.read(firestoreSyncServiceProvider).syncLiquidCash(_currentUid!, amount);
    }
  }

  void updateLiquidCash(double amount) {
    state = amount;
    _persist(amount);
  }

  void addIncome(double amount) {
    final next = state + amount;
    state = next;
    _persist(next);
  }

  void deductCash(double amount) {
    final next = (state - amount).clamp(0.0, double.infinity);
    state = next;
    _persist(next);
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, double>(DashboardController.new);
