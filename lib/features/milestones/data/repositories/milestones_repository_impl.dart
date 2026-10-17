import '../../domain/repositories/milestones_repository.dart';
import '../models/milestones_model.dart';

class MilestonesRepositoryImpl implements MilestonesRepository {
  const MilestonesRepositoryImpl();

  @override
  Future<MilestonesModel> getMilestones() async {
    return const MilestonesModel();
  }
}
