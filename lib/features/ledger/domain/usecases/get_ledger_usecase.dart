import '../entities/ledger.dart';
import '../repositories/ledger_repository.dart';

class GetLedgerUseCase {
  final LedgerRepository repository;

  const GetLedgerUseCase(this.repository);

  Future<Ledger> execute() {
    return repository.getLedger();
  }
}
