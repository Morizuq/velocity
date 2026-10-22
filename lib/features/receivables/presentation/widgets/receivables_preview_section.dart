import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../controllers/receivables_controller.dart';
import 'add_receivable_dialog.dart';
import 'receivable_card.dart';

/// Executive dashboard preview section showing the top active receivable claims,
/// collections summary, and direct links to the dedicated Receivables Hub.
class ReceivablesPreviewSection extends ConsumerWidget {
  const ReceivablesPreviewSection({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddReceivableDialog(
        onAddConfirmed: ({
          required debtor,
          required totalAmount,
          required initialReceived,
          required type,
          description,
          dueDate,
          invoiceNumber,
          notes,
        }) {
          ref
              .read(receivablesControllerProvider.notifier)
              .addReceivable(
                debtor: debtor,
                description: description,
                totalAmount: totalAmount,
                initialReceived: initialReceived,
                type: type,
                dueDate: dueDate,
                invoiceNumber: invoiceNumber,
                notes: notes,
              );
          if (initialReceived > 0) {
            ref
                .read(dashboardControllerProvider.notifier)
                .addIncome(initialReceived);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final items = ref.watch(receivablesControllerProvider);
    final receivablesNotifier = ref.read(
      receivablesControllerProvider.notifier,
    );
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    final settledCount = items.where((i) => i.isSettled).length;
    final pendingCount = items.where((i) => !i.isSettled).length;
    final activeItems = items.where((i) => !i.isSettled).toList();
    final settledItems = items.where((i) => i.isSettled).toList();
    final previewActive = activeItems.take(3).toList();

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
                    'The Receivables Bucket',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '$pendingCount pending inflows • $settledCount collected',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (items.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => context.go(Routes.receivables),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text('View Hub (${items.length})'),
                    style: TextButton.styleFrom(
                      foregroundColor: brandColors.receivable,
                    ),
                  ),
                  AppSpacing.hXS,
                ],
                FilledButton.tonalIcon(
                  onPressed: () => _showAddDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Claim',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColors.subtle,
                    foregroundColor: brandColors.receivable,
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
          ],
        ),
        AppSpacing.vM,
        if (items.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: brandColors.receivable,
            badgeLabel: 'INFLOWS CLEAR',
            badgeColor: brandColors.receivable,
            title: 'No Pending Receivables',
            description:
                'Track money owed to you: freelance invoices, personal loans, or reimbursements. When payments arrive, they automatically credit your liquid cash.',
            actionLabel: 'Log First Receivable',
            onAction: () => _showAddDialog(context, ref),
          )
        else ...[
          for (final item in previewActive)
            Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: ReceivableCard(
                receivable: item,
                onLogPayment: (amount) {
                  receivablesNotifier.logPayment(item.id, amount);
                  dashboardNotifier.addIncome(amount);
                },
                onToggleSettled: () =>
                    receivablesNotifier.toggleSettled(item.id),
                onDelete: () => receivablesNotifier.deleteReceivable(item.id),
              ),
            ),
          if (activeItems.length > 3)
            InkWell(
              onTap: () => context.go(Routes.receivables),
              borderRadius: AppBorderRadius.allM,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: brandColors.subtle,
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.receivable.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: brandColors.receivable,
                    ),
                    AppSpacing.hS,
                    Text(
                      '+ ${activeItems.length - 3} more pending claims • Open Receivables Hub',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: brandColors.receivable,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (settledItems.isNotEmpty) ...[
            AppSpacing.vS,
            InkWell(
              onTap: () => context.go(Routes.receivables),
              borderRadius: AppBorderRadius.allM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: brandColors.progress.withValues(alpha: 0.05),
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.progress.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 16,
                      color: brandColors.progress,
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Text(
                        '${settledItems.length} claim(s) fully collected and archived',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: brandColors.progress,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: brandColors.progress,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
