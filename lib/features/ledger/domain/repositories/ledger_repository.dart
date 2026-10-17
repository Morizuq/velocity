import '../entities/ledger.dart';

abstract class LedgerRepository {
  Future<Ledger> getLedger();
}
