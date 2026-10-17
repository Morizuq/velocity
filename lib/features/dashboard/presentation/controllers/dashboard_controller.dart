import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier managing high-level liquid cash balance and user metrics.
class DashboardController extends Notifier<double> {
  @override
  double build() {
    // Initial liquid cash as specified in project scope users collection
    return 850000.0;
  }

  void updateLiquidCash(double amount) {
    state = amount;
  }

  void addIncome(double amount) {
    state = state + amount;
  }

  void deductCash(double amount) {
    state = (state - amount).clamp(0.0, double.infinity);
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, double>(
  DashboardController.new,
);
