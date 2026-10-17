import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';

/// State notifier managing high-level liquid cash balance with local persistence.
class DashboardController extends Notifier<double> {
  static const _storageKey = 'velocity_liquid_cash';

  @override
  double build() {
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

  void _persist(double amount) {
    try {
      final storage = ref.read(storageServiceProvider);
      storage.setString(_storageKey, amount.toString());
    } catch (_) {}
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
