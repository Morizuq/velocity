import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_border_width.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/milestone_entity.dart';
import 'fund_milestone_dialog.dart';

/// Card component presenting an upcoming purchase milestone with progress bars and allocation actions.
class MilestoneCard extends StatelessWidget {
  final MilestoneEntity milestone;
  final ValueChanged<double> onFundMilestone;

  const MilestoneCard({
    super.key,
    required this.milestone,
    required this.onFundMilestone,
  });

  void _showFundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => FundMilestoneDialog(
        milestone: milestone,
        onFundConfirmed: onFundMilestone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Container(
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allL,
        border: Border.all(
          color: milestone.isCompleted
              ? brandColors.progress.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon, Title, and Percentage Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: milestone.isCompleted
                          ? brandColors.progress.withValues(alpha: 0.15)
                          : brandColors.milestone.withValues(alpha: 0.15),
                      borderRadius: AppBorderRadius.allM,
                    ),
                    child: Icon(
                      milestone.isCompleted
                          ? Icons.verified_rounded
                          : Icons.flag_rounded,
                      size: AppIconSize.s,
                      color: milestone.isCompleted
                          ? brandColors.progress
                          : brandColors.milestone,
                    ),
                  ),
                  AppSpacing.hS,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      Text(
                        milestone.isCompleted ? 'Goal Achieved' : 'In Progress',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: milestone.isCompleted
                              ? brandColors.progress
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: milestone.isCompleted
                      ? brandColors.progress.withValues(alpha: 0.15)
                      : brandColors.milestone.withValues(alpha: 0.15),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Text(
                  milestone.isCompleted ? 'READY' : '${milestone.progressPercentage}% FUNDED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: milestone.isCompleted
                        ? brandColors.progress
                        : brandColors.milestone,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vM,

          // Amounts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accumulated',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(milestone.currentAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: milestone.isCompleted
                          ? brandColors.progress
                          : brandColors.milestone,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target Budget',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(milestone.targetAmount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.vS,

          // Progress Bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: milestone.progressRatio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                milestone.isCompleted ? brandColors.progress : brandColors.milestone,
              ),
            ),
          ),
          AppSpacing.vM,

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: milestone.isCompleted ? null : () => _showFundDialog(context),
              icon: const Icon(Icons.add_circle_outline_rounded, size: AppIconSize.s),
              label: const Text('Allocate Capital'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: AppBorderWidth.hairline,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.allM,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
