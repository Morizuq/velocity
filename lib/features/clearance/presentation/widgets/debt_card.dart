import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_border_width.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/debt_entity.dart';
import 'log_payment_dialog.dart';

/// Interactive card component displaying a single debt account and paydown status.
class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final ValueChanged<double> onLogPayment;
  final VoidCallback onToggleCleared;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onLogPayment,
    required this.onToggleCleared,
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

    return Container(
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allL,
        border: Border.all(
          color: debt.isCleared
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
          // Header with Creditor Name and Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: debt.isCleared
                          ? brandColors.progress.withValues(alpha: 0.15)
                          : brandColors.debt.withValues(alpha: 0.15),
                      borderRadius: AppBorderRadius.allM,
                    ),
                    child: Icon(
                      debt.isCleared
                          ? Icons.check_circle_rounded
                          : Icons.account_balance_wallet_outlined,
                      size: AppIconSize.s,
                      color: debt.isCleared ? brandColors.progress : brandColors.debt,
                    ),
                  ),
                  AppSpacing.hS,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.creditor,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      Text(
                        debt.isCleared ? 'Cleared' : 'Pending Clearance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: debt.isCleared
                              ? brandColors.progress
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: debt.isCleared
                      ? brandColors.progress.withValues(alpha: 0.15)
                      : brandColors.debt.withValues(alpha: 0.15),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Text(
                  debt.isCleared ? '100%' : '${debt.progressPercentage}% PAID',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: debt.isCleared ? brandColors.progress : brandColors.debt,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vM,

          // Balance metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Due',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(debt.remainingAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: debt.isCleared
                          ? theme.colorScheme.onSurfaceVariant
                          : brandColors.debt,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Initial',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(debt.totalOwed),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.vS,

          // Animated Progress Bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: debt.progressRatio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                child: OutlinedButton.icon(
                  onPressed: debt.isCleared ? null : () => _showPaymentDialog(context),
                  icon: const Icon(Icons.payment_rounded, size: AppIconSize.s),
                  label: const Text('Log Payment'),
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
              AppSpacing.hS,
              IconButton.outlined(
                tooltip: debt.isCleared ? 'Mark Active' : 'Mark Cleared',
                onPressed: onToggleCleared,
                icon: Icon(
                  debt.isCleared
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  size: AppIconSize.s,
                  color: debt.isCleared ? theme.colorScheme.outline : brandColors.progress,
                ),
                style: IconButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: AppBorderWidth.hairline,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.allM,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
