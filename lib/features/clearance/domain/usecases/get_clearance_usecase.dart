import '../entities/clearance.dart';
import '../repositories/clearance_repository.dart';

class GetClearanceUseCase {
  final ClearanceRepository repository;

  const GetClearanceUseCase(this.repository);

  Future<Clearance> execute() {
    return repository.getClearance();
  }
}
