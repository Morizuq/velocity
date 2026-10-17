import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/milestone_entity.dart';
import 'adjust_milestone_fund_dialog.dart';

/// Card component presenting an upcoming purchase milestone, sizing tightly to content.
class MilestoneCard extends StatelessWidget {
  final MilestoneEntity milestone;
  final void Function(double delta) onAdjustDelta;
  final void Function(double newTotal) onSetExactTotal;
  final VoidCallback? onDelete;

  const MilestoneCard({
    super.key,
    required this.milestone,
    required this.onAdjustDelta,
    required this.onSetExactTotal,
    this.onDelete,
  });

  void _showAdjustDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AdjustMilestoneFundDialog(
        milestone: milestone,
        onAdjustDelta: onAdjustDelta,
        onSetExactTotal: onSetExactTotal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allL,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : const Color(0x06000000),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Critical: Tightly wrap content, zero vacant voids
        children: [
          // Header with Icon, Title, and Percentage Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: milestone.isCompleted
                            ? brandColors.progress.withValues(alpha: 0.15)
                            : brandColors.milestone.withValues(alpha: 0.15),
                        borderRadius: AppBorderRadius.allS,
                      ),
                      child: Icon(
                        milestone.isCompleted
                            ? Icons.verified_rounded
                            : Icons.flag_rounded,
                        size: AppIconSize.s - 2,
                        color: milestone.isCompleted
                            ? brandColors.progress
                            : brandColors.milestone,
                      ),
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            milestone.isCompleted ? 'Goal Achieved' : 'In Progress',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: milestone.isCompleted
                                  ? brandColors.progress
                                  : theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                              fontWeight: AppFontWeight.medium,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hS,
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: milestone.isCompleted
                          ? brandColors.progress.withValues(alpha: 0.12)
                          : brandColors.milestone.withValues(alpha: 0.12),
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Text(
                      milestone.isCompleted ? 'READY' : '${milestone.progressPercentage}% FUNDED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: milestone.isCompleted
                            ? brandColors.progress
                            : brandColors.milestone,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (onDelete != null) ...[
                    AppSpacing.hXXS,
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      onPressed: onDelete,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ],
          ),
          AppSpacing.vM,

          // Amounts row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accumulated',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vXXS,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        FinancialNumberFormatter.format(milestone.currentAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: milestone.isCompleted
                              ? brandColors.progress
                              : brandColors.milestone,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target Budget',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vXXS,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        FinancialNumberFormatter.format(milestone.targetAmount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: AppFontWeight.semiBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vS,

          // Sleek Progress Bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: milestone.progressRatio,
              minHeight: 5,
              backgroundColor: isDark
                  ? const Color(0xFF1B2230)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                milestone.isCompleted ? brandColors.progress : brandColors.milestone,
              ),
            ),
          ),
          AppSpacing.vM,

          // Action Button: Sized tightly to content
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _showAdjustDialog(context),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Adjust / Allocate Funds', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1B2334)
                    : const Color(0xFFF1F5F9),
                foregroundColor: theme.colorScheme.onSurface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.allM,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
