import '../entities/milestones.dart';

abstract class MilestonesRepository {
  Future<Milestones> getMilestones();
}
