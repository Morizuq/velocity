import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/headers/velocity_page_header.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';
import 'controllers/milestones_controller.dart';
import 'widgets/add_milestone_dialog.dart';
import 'widgets/milestones_bucket_section.dart';

/// Full-screen dedicated workspace for managing all milestone savings goals.
class MilestonesPage extends ConsumerWidget {
  const MilestonesPage({super.key});

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
    final totalTarget = ref.watch(totalMilestoneTargetProvider);
    final totalSaved = ref.watch(totalMilestoneSavedProvider);

    final completedCount = milestones.where((m) => m.isCompleted).length;
    final activeCount = milestones.where((m) => !m.isCompleted).length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSpacing.m,
              tablet: AppSpacing.xl,
              desktop: AppSpacing.xxl,
            ),
            vertical: AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              VelocityPageHeader(
                title: 'Milestone Goals',
                subtitle:
                    'Allocate capital toward upcoming major milestones and targets.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _showAddMilestoneDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Milestone'),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColors.milestone,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.pill,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vL,

              // Metric Highlights
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 550 && !isWide;

                  final savedCard = VelocityMetricCard(
                    title: 'Total Capital Allocated',
                    value: FinancialNumberFormatter.format(totalSaved),
                    subtitle: '$completedCount Completed Goals',
                    icon: Icons.savings_outlined,
                    accentColor: brandColors.milestone,
                  );

                  final targetCard = VelocityMetricCard(
                    title: 'Total Milestone Target',
                    value: FinancialNumberFormatter.format(totalTarget),
                    subtitle: '$activeCount Active Goals in Progress',
                    icon: Icons.flag_rounded,
                    accentColor: brandColors.progress,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: savedCard),
                        AppSpacing.hM,
                        Expanded(child: targetCard),
                      ],
                    );
                  }
                  if (isMedium) {
                    return Row(
                      children: [
                        Expanded(child: savedCard),
                        AppSpacing.hM,
                        Expanded(child: targetCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      savedCard,
                      AppSpacing.vM,
                      targetCard,
                    ],
                  );
                },
              ),
              AppSpacing.vXL,

              // Full Milestones Section
              const MilestonesBucketSection(isPreviewMode: false),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }
}
