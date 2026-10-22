import '../entities/recurring_cashflow_entity.dart';

/// Contract defining persistence and synchronization operations for recurring cash flows.
abstract interface class RecurringCashflowRepository {
  Stream<List<RecurringCashflowEntity>> watchRecurringCashflows();
  Future<List<RecurringCashflowEntity>> getRecurringCashflows();
  Future<void> saveRecurringCashflows(List<RecurringCashflowEntity> items);
  Future<void> deleteRecurringCashflow(String id);
}
