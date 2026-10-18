import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/debt_entity.dart';
import 'log_payment_dialog.dart';

/// Interactive card component displaying a single debt account, sizing strictly to its content.
class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final ValueChanged<double> onLogPayment;
  final VoidCallback onToggleCleared;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onLogPayment,
    required this.onToggleCleared,
    this.onDelete,
    this.dragHandle,
  });

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => LogPaymentDialog(
        debt: debt,
        onPaymentConfirmed: onLogPayment,
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
        mainAxisSize: MainAxisSize.min, // Critical: Size to content without artificial empty voids
        children: [
          // Header with Creditor Name and Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (dragHandle != null) ...[
                      dragHandle!,
                      AppSpacing.hXS,
                    ],
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: debt.isCleared
                            ? brandColors.progress.withValues(alpha: 0.15)
                            : brandColors.debt.withValues(alpha: 0.15),
                        borderRadius: AppBorderRadius.allS,
                      ),
                      child: Icon(
                        debt.isCleared
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_outlined,
                        size: AppIconSize.s - 2,
                        color: debt.isCleared
                            ? brandColors.progress
                            : brandColors.debt,
                      ),
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.creditor,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            debt.isCleared ? 'Cleared' : 'Pending Clearance',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: debt.isCleared
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
                      color: debt.isCleared
                          ? brandColors.progress.withValues(alpha: 0.12)
                          : brandColors.debt.withValues(alpha: 0.12),
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Text(
                      debt.isCleared ? 'CLEARED' : '${debt.progressPercentage}% PAID',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: debt.isCleared ? brandColors.progress : brandColors.debt,
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

          // Balance metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Due',
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
                        FinancialNumberFormatter.format(debt.remainingAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: debt.isCleared
                              ? theme.colorScheme.onSurfaceVariant
                              : brandColors.debt,
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
                      'Total Initial',
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
                        FinancialNumberFormatter.format(debt.totalOwed),
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
              value: debt.progressRatio,
              minHeight: 5,
              backgroundColor: isDark
                  ? const Color(0xFF1B2230)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                debt.isCleared ? brandColors.progress : brandColors.debt,
              ),
            ),
          ),
          AppSpacing.vM,

          // Action row
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: debt.isCleared ? null : () => _showPaymentDialog(context),
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: const Text('Log Payment', style: TextStyle(fontSize: 12)),
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
              AppSpacing.hS,
              IconButton.filledTonal(
                tooltip: debt.isCleared ? 'Mark Active' : 'Mark Cleared',
                onPressed: onToggleCleared,
                icon: Icon(
                  debt.isCleared ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: debt.isCleared ? theme.colorScheme.outline : brandColors.progress,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1B2334)
                      : const Color(0xFFF1F5F9),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.allM,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
