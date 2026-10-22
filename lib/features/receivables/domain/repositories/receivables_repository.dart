import '../entities/receivable_entity.dart';

/// Contract defining persistence and synchronization operations for receivables.
abstract interface class ReceivablesRepository {
  Stream<List<ReceivableEntity>> watchReceivables();
  Future<List<ReceivableEntity>> getReceivables();
  Future<void> saveReceivables(List<ReceivableEntity> receivables);
  Future<void> deleteReceivable(String id);
}
