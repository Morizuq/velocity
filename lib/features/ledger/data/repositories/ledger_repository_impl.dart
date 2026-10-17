import '../../domain/repositories/ledger_repository.dart';
import '../models/ledger_model.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  const LedgerRepositoryImpl();

  @override
  Future<LedgerModel> getLedger() async {
    return const LedgerModel();
  }
}
