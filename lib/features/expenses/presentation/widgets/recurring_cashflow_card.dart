import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/cashflow_direction.dart';
import '../../domain/entities/recurring_cashflow_entity.dart';

/// Interactive card component displaying a single recurring monthly commitment or salary.
class RecurringCashflowCard extends StatelessWidget {
  final RecurringCashflowEntity cashflow;
  final VoidCallback onToggleSettledCurrentCycle;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  const RecurringCashflowCard({
    super.key,
    required this.cashflow,
    required this.onToggleSettledCurrentCycle,
    this.onDelete,
    this.dragHandle,
  });

  IconData _iconForCategory(String category, CashflowDirection direction) {
    if (direction == CashflowDirection.inflowReceivable) {
      return Icons.payments_rounded;
    }
    final lower = category.toLowerCase();
    if (lower.contains('telecom') ||
        lower.contains('internet') ||
        lower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('housing') || lower.contains('rent')) {
      return Icons.home_rounded;
    }
    if (lower.contains('software') || lower.contains('cloud')) {
      return Icons.cloud_queue_rounded;
    }
    if (lower.contains('utility')) {
      return Icons.bolt_rounded;
    }
    return Icons.subscriptions_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;
    final isOutflow = cashflow.direction == CashflowDirection.outflowPayable;
    final daysUntil = cashflow.daysUntilDue();

    final statusColor = cashflow.isSettledThisMonth
        ? brandColors.progress
        : cashflow.isOverdue
        ? brandColors.debt
        : cashflow.isDueToday
        ? brandColors.receivable
        : theme.colorScheme.onSurfaceVariant;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (dragHandle != null) ...[dragHandle!, AppSpacing.hXS],
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            (isOutflow
                                    ? brandColors.debt
                                    : brandColors.progress)
                                .withValues(alpha: 0.15),
                        borderRadius: AppBorderRadius.allS,
                      ),
                      child: Icon(
                        _iconForCategory(cashflow.category, cashflow.direction),
                        size: AppIconSize.s - 2,
                        color: isOutflow
                            ? brandColors.debt
                            : brandColors.progress,
                      ),
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cashflow.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.vXXS,
                          Row(
                            children: [
                              Text(
                                cashflow.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                ' • Every ${cashflow.dayOfMonth}${_daySuffix(cashflow.dayOfMonth)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cashflow.isSettledThisMonth
                          ? Icons.check_circle_rounded
                          : cashflow.isOverdue
                          ? Icons.error_outline_rounded
                          : Icons.schedule_rounded,
                      size: 11,
                      color: statusColor,
                    ),
                    AppSpacing.hXXS,
                    Text(
                      cashflow.isSettledThisMonth
                          ? (isOutflow ? 'PAID THIS MONTH' : 'RECEIVED')
                          : cashflow.isOverdue
                          ? 'OVERDUE'
                          : cashflow.isDueToday
                          ? 'DUE TODAY'
                          : 'DUE IN ${daysUntil}D',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: statusColor,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vM,

          // Amount & Billing Cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOutflow ? 'Monthly Charge' : 'Monthly Credit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(cashflow.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: isOutflow
                          ? (cashflow.isSettledThisMonth
                                ? theme.colorScheme.onSurfaceVariant
                                : brandColors.debt)
                          : brandColors.progress,
                    ),
                  ),
                ],
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    onPressed: onToggleSettledCurrentCycle,
                    style: FilledButton.styleFrom(
                      backgroundColor: cashflow.isSettledThisMonth
                          ? brandColors.subtle
                          : (isOutflow
                                    ? brandColors.debt
                                    : brandColors.progress)
                                .withValues(alpha: 0.12),
                      foregroundColor: cashflow.isSettledThisMonth
                          ? theme.colorScheme.onSurfaceVariant
                          : (isOutflow
                                ? brandColors.debt
                                : brandColors.progress),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s + 2,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.pill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cashflow.isSettledThisMonth
                              ? Icons.undo_rounded
                              : Icons.check_rounded,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          cashflow.isSettledThisMonth
                              ? 'Undo'
                              : (isOutflow ? 'Mark Paid' : 'Mark Received'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                      tooltip: 'Remove Commitment',
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _daySuffix(int day) {
    if (day == 1 || day == 21 || day == 31) return 'st';
    if (day == 2 || day == 22) return 'nd';
    if (day == 3 || day == 23) return 'rd';
    return 'th';
  }
}
