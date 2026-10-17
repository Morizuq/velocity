import '../entities/milestones.dart';
import '../repositories/milestones_repository.dart';

class GetMilestonesUseCase {
  final MilestonesRepository repository;

  const GetMilestonesUseCase(this.repository);

  Future<Milestones> execute() {
    return repository.getMilestones();
  }
}
