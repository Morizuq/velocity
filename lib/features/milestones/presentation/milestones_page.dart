import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import 'controllers/milestones_controller.dart';
import 'widgets/milestone_card.dart';

/// Presentation page for the Milestones bucket.
class MilestonesPage extends ConsumerWidget {
  const MilestonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(milestonesControllerProvider);
    final milestonesNotifier = ref.read(milestonesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestone Goals'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: milestones.length,
        separatorBuilder: (context, index) => AppSpacing.vM,
        itemBuilder: (context, index) {
          final milestone = milestones[index];
          return MilestoneCard(
            milestone: milestone,
            onFundMilestone: (amount) =>
                milestonesNotifier.allocateFunds(milestone.id, amount),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allXL),
        onPressed: () {
          milestonesNotifier.addMilestone(
            title: 'New Goal',
            targetAmount: 200000,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
