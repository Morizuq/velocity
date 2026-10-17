import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/milestone_entity.dart';

/// State notifier managing milestone savings targets and fund allocations.
class MilestonesController extends Notifier<List<MilestoneEntity>> {
  @override
  List<MilestoneEntity> build() {
    return const [
      MilestoneEntity(
        id: 'milestone_rent',
        title: 'Rent',
        targetAmount: 1200000,
        currentAmount: 750000,
        isCompleted: false,
      ),
      MilestoneEntity(
        id: 'milestone_workspace',
        title: 'Workspace Table + Chair',
        targetAmount: 300000,
        currentAmount: 180000,
        isCompleted: false,
      ),
      MilestoneEntity(
        id: 'milestone_nvme',
        title: '1TB NVMe SSD',
        targetAmount: 120000,
        currentAmount: 120000,
        isCompleted: true,
      ),
      MilestoneEntity(
        id: 'milestone_bed',
        title: 'Big Bed',
        targetAmount: 450000,
        currentAmount: 150000,
        isCompleted: false,
      ),
    ];
  }

  /// Allocates savings funds towards an upcoming milestone purchase.
  void allocateFunds(String milestoneId, double amount) {
    state = [
      for (final milestone in state)
        if (milestone.id == milestoneId)
          milestone.copyWith(
            currentAmount: (milestone.currentAmount + amount).clamp(
              0.0,
              milestone.targetAmount,
            ),
          )
        else
          milestone,
    ];
  }

  /// Adds a new milestone savings goal.
  void addMilestone({required String title, required double targetAmount}) {
    final newMilestone = MilestoneEntity(
      id: 'milestone_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      isCompleted: false,
    );
    state = [...state, newMilestone];
  }
}

final milestonesControllerProvider =
    NotifierProvider<MilestonesController, List<MilestoneEntity>>(
  MilestonesController.new,
);

/// Provider computing total target savings across all milestone goals.
final totalMilestoneTargetProvider = Provider<double>((ref) {
  final milestones = ref.watch(milestonesControllerProvider);
  return milestones.fold<double>(0.0, (sum, m) => sum + m.targetAmount);
});

/// Provider computing total accumulated milestone savings.
final totalMilestoneSavedProvider = Provider<double>((ref) {
  final milestones = ref.watch(milestonesControllerProvider);
  return milestones.fold<double>(0.0, (sum, m) => sum + m.currentAmount);
});
