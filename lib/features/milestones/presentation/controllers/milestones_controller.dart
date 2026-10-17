import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../domain/entities/milestone_entity.dart';

/// State notifier managing milestone savings targets, fund adjustments, and local persistence.
class MilestonesController extends Notifier<List<MilestoneEntity>> {
  static const _storageKey = 'velocity_milestones';

  @override
  List<MilestoneEntity> build() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => MilestoneEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  void _persist(List<MilestoneEntity> updated) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((m) => m.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}
  }

  /// Allocates savings funds towards an upcoming milestone purchase.
  void allocateFunds(String milestoneId, double amount) {
    adjustFunds(milestoneId, amount);
  }

  /// Adjusts funds by a positive or negative delta (e.g. depositing or removing funds).
  void adjustFunds(String milestoneId, double deltaAmount) {
    final updated = [
      for (final milestone in state)
        if (milestone.id == milestoneId)
          milestone.copyWith(
            currentAmount: (milestone.currentAmount + deltaAmount).clamp(
              0.0,
              milestone.targetAmount,
            ),
          )
        else
          milestone,
    ];
    state = updated;
    _persist(updated);
  }

  /// Sets the milestone accumulated balance directly to a specific value.
  void setMilestoneAmount(String milestoneId, double newAmount) {
    final updated = [
      for (final milestone in state)
        if (milestone.id == milestoneId)
          milestone.copyWith(
            currentAmount: newAmount.clamp(0.0, milestone.targetAmount),
          )
        else
          milestone,
    ];
    state = updated;
    _persist(updated);
  }

  /// Adds a new milestone savings goal.
  void addMilestone({
    required String title,
    required double targetAmount,
    double initialAmount = 0.0,
  }) {
    final newMilestone = MilestoneEntity(
      id: 'milestone_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      isCompleted: initialAmount >= targetAmount && targetAmount > 0,
    );
    final updated = [...state, newMilestone];
    state = updated;
    _persist(updated);
  }

  /// Deletes a milestone.
  void deleteMilestone(String milestoneId) {
    final updated = state.where((m) => m.id != milestoneId).toList();
    state = updated;
    _persist(updated);
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
