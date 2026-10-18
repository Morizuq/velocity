import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../controllers/milestones_controller.dart';
import 'add_milestone_dialog.dart';
import 'milestone_card.dart';

/// Section widget rendering the Milestone Bucket savings targets with drag-and-drop reordering.
class MilestonesBucketSection extends ConsumerWidget {
  const MilestonesBucketSection({super.key});

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddMilestoneDialog(
        onAddConfirmed: (title, target, initial) {
          ref
              .read(milestonesControllerProvider.notifier)
              .addMilestone(
                title: title,
                targetAmount: target,
                initialAmount: initial,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final milestones = ref.watch(milestonesControllerProvider);
    final milestonesNotifier = ref.read(milestonesControllerProvider.notifier);
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Milestone Bucket',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '${milestones.where((m) => m.isCompleted).length} of ${milestones.length} fulfilled goals',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.hS,
            FilledButton.tonalIcon(
              onPressed: () => _showAddMilestoneDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Goal', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: brandColors.subtle,
                foregroundColor: brandColors.milestone,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.pill,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vM,
        if (milestones.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.flag_rounded,
            iconColor: brandColors.milestone,
            badgeLabel: 'SAVINGS TARGETS',
            badgeColor: brandColors.milestone,
            title: 'No Milestone Buckets Created',
            description:
                'Define dedicated savings targets for upcoming big purchases (e.g. Rent, Workstation, Vacations) to focus your capital velocity.',
            actionLabel: 'Create First Milestone Goal',
            onAction: () => _showAddMilestoneDialog(context, ref),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 6,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              borderRadius: AppBorderRadius.allL,
              child: child,
            ),
            itemCount: milestones.length,
            onReorderItem: milestonesNotifier.reorder,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              return Padding(
                key: ValueKey(milestone.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: MilestoneCard(
                    milestone: milestone,
                    dragHandle: ReorderableDragStartListener(
                      index: index,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                          ),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    onAdjustDelta: (delta) {
                      milestonesNotifier.adjustFunds(milestone.id, delta);
                      if (delta > 0) {
                        dashboardNotifier.deductCash(delta);
                      } else {
                        dashboardNotifier.addIncome(delta.abs());
                      }
                    },
                    onSetExactTotal: (newTotal) {
                      final diff = newTotal - milestone.currentAmount;
                      milestonesNotifier.setMilestoneAmount(
                        milestone.id,
                        newTotal,
                      );
                      if (diff > 0) {
                        dashboardNotifier.deductCash(diff);
                      } else {
                        dashboardNotifier.addIncome(diff.abs());
                      }
                    },
                    onDelete: () =>
                        milestonesNotifier.deleteMilestone(milestone.id),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
