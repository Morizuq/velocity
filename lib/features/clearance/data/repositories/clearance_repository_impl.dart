import '../../domain/repositories/clearance_repository.dart';
import '../models/clearance_model.dart';

class ClearanceRepositoryImpl implements ClearanceRepository {
  const ClearanceRepositoryImpl();

  @override
  Future<ClearanceModel> getClearance() async {
    return const ClearanceModel();
  }
}
