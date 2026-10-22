import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/receivable_entity.dart';
import '../../domain/entities/receivable_type.dart';
import 'log_receivable_payment_dialog.dart';
import 'receivable_card_footer.dart';

/// Interactive card component displaying a single receivable claim, sizing strictly to its content.
class ReceivableCard extends StatelessWidget {
  final ReceivableEntity receivable;
  final ValueChanged<double> onLogPayment;
  final VoidCallback onToggleSettled;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  const ReceivableCard({
    super.key,
    required this.receivable,
    required this.onLogPayment,
    required this.onToggleSettled,
    this.onDelete,
    this.dragHandle,
  });

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => LogReceivablePaymentDialog(
        receivable: receivable,
        onPaymentConfirmed: onLogPayment,
      ),
    );
  }

  IconData _iconForType(ReceivableType type) {
    switch (type) {
      case ReceivableType.freelanceInvoice:
        return Icons.receipt_long_rounded;
      case ReceivableType.personalLoan:
        return Icons.handshake_rounded;
      case ReceivableType.reimbursement:
        return Icons.assignment_return_rounded;
    }
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Debtor Name, Category Badge, and Drag Handle
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
                        color: receivable.isSettled
                            ? brandColors.progress.withValues(alpha: 0.15)
                            : brandColors.receivable.withValues(alpha: 0.15),
                        borderRadius: AppBorderRadius.allS,
                      ),
                      child: Icon(
                        receivable.isSettled
                            ? Icons.check_circle_rounded
                            : _iconForType(receivable.type),
                        size: AppIconSize.s - 2,
                        color: receivable.isSettled
                            ? brandColors.progress
                            : brandColors.receivable,
                      ),
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receivable.debtor,
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
                                receivable.type.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                              if (receivable.invoiceNumber != null) ...[
                                Text(
                                  ' • ',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brandColors.subtle,
                                    borderRadius: AppBorderRadius.allS,
                                  ),
                                  child: Text(
                                    receivable.invoiceNumber!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: AppFontWeight.semiBold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (receivable.description != null &&
                              receivable.description!.trim().isNotEmpty) ...[
                            AppSpacing.vXXS,
                            Text(
                              receivable.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chip
              _buildStatusBadge(context, brandColors, theme),
            ],
          ),
          AppSpacing.vM,

          // Remaining Balance & Total Claim
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable.isSettled
                        ? 'Total Collected'
                        : 'Outstanding Balance',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(
                      receivable.isSettled
                          ? receivable.totalAmount
                          : receivable.remainingBalance,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: receivable.isSettled
                          ? brandColors.progress
                          : brandColors.receivable,
                    ),
                  ),
                ],
              ),
              if (!receivable.isSettled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target Claim',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      FinancialNumberFormatter.format(receivable.totalAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: AppFontWeight.semiBold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          AppSpacing.vS,

          // Linear Collection Progress Bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: receivable.collectionProgress,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                receivable.isSettled
                    ? brandColors.progress
                    : brandColors.receivable,
              ),
              minHeight: 5,
            ),
          ),
          AppSpacing.vS,
          // Footer: Repayment Date & Actions
          ReceivableCardFooter(
            receivable: receivable,
            onRecordPayment: () => _showPaymentDialog(context),
            onToggleSettled: onToggleSettled,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    BrandColors brandColors,
    ThemeData theme,
  ) {
    if (receivable.isSettled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: brandColors.progress.withValues(alpha: 0.12),
          borderRadius: AppBorderRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: brandColors.progress),
            AppSpacing.hXXS,
            Text(
              'COLLECTED',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: AppFontWeight.bold,
                color: brandColors.progress,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    if (receivable.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: brandColors.debt.withValues(alpha: 0.12),
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          'OVERDUE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.bold,
            color: brandColors.debt,
            fontSize: 10,
          ),
        ),
      );
    }
    if (receivable.isDueSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: brandColors.receivable.withValues(alpha: 0.12),
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          'DUE SOON (${receivable.daysUntilDue}d)',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.bold,
            color: brandColors.receivable,
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
