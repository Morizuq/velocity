import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../domain/entities/receivable_entity.dart';

/// Clean footer bar for a receivable card, rendering repayment timeline and action triggers.
class ReceivableCardFooter extends StatelessWidget {
  final ReceivableEntity receivable;
  final VoidCallback onRecordPayment;
  final VoidCallback onToggleSettled;
  final VoidCallback? onDelete;

  const ReceivableCardFooter({
    super.key,
    required this.receivable,
    required this.onRecordPayment,
    required this.onToggleSettled,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Due Date label
        if (receivable.dueDate != null)
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 13,
                color: receivable.isOverdue
                    ? brandColors.debt
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              AppSpacing.hXXS,
              Text(
                DateFormat('MMM d, yyyy').format(receivable.dueDate!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: receivable.isOverdue
                      ? brandColors.debt
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                  fontWeight: receivable.isOverdue
                      ? AppFontWeight.bold
                      : AppFontWeight.regular,
                  fontSize: 11,
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),

        // Action Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!receivable.isSettled) ...[
              FilledButton.tonal(
                onPressed: onRecordPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: brandColors.receivable.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: brandColors.receivable,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s + 2,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.pill,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14),
                    SizedBox(width: 2),
                    Text('Record Payment', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              AppSpacing.hXS,
            ],
            IconButton(
              icon: Icon(
                receivable.isSettled
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: receivable.isSettled
                    ? theme.colorScheme.onSurfaceVariant
                    : brandColors.progress,
              ),
              tooltip: receivable.isSettled
                  ? 'Reopen Claim'
                  : 'Mark Fully Collected',
              onPressed: onToggleSettled,
              visualDensity: VisualDensity.compact,
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
                tooltip: 'Delete Claim',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}
