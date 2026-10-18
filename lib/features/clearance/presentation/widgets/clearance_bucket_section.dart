import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../controllers/clearance_controller.dart';
import 'add_debt_dialog.dart';
import 'debt_card.dart';

/// Section widget rendering the Clearance Bucket list with drag-and-drop reordering.
class ClearanceBucketSection extends ConsumerWidget {
  const ClearanceBucketSection({super.key});

  void _showAddDebtDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddDebtDialog(
        onAddConfirmed: (creditor, total, paid) {
          ref
              .read(clearanceControllerProvider.notifier)
              .addDebt(creditor: creditor, totalOwed: total, initialPaid: paid);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final debts = ref.watch(clearanceControllerProvider);
    final clearanceNotifier = ref.read(clearanceControllerProvider.notifier);
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
                    'The Clearance Bucket',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '${debts.where((d) => d.isCleared).length} of ${debts.length} cleared accounts',
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
              onPressed: () => _showAddDebtDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Debt', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: brandColors.subtle,
                foregroundColor: brandColors.debt,
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
        if (debts.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.verified_user_rounded,
            iconColor: brandColors.progress,
            badgeLabel: 'CLEARANCE ZERO',
            badgeColor: brandColors.progress,
            title: 'Clearance Bucket is Clean',
            description:
                'No pending debts or active liabilities. Log any loans, IOUs, or credit balances to start monitoring your burn-down trajectory.',
            actionLabel: 'Log First Debt Account',
            onAction: () => _showAddDebtDialog(context, ref),
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
            itemCount: debts.length,
            onReorderItem: clearanceNotifier.reorder,
            itemBuilder: (context, index) {
              final debt = debts[index];
              return Padding(
                key: ValueKey(debt.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: DebtCard(
                    debt: debt,
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
                    onLogPayment: (amount) {
                      clearanceNotifier.logPayment(debt.id, amount);
                      dashboardNotifier.deductCash(amount);
                    },
                    onToggleCleared: () =>
                        clearanceNotifier.toggleCleared(debt.id),
                    onDelete: () => clearanceNotifier.deleteDebt(debt.id),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
