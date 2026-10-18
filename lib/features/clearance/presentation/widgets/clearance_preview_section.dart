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
import '../controllers/clearance_controller.dart';
import 'add_debt_dialog.dart';
import 'debt_card.dart';

/// Executive dashboard preview section showing the top 3 active clearance accounts,
/// sunk settled summary, and direct deep links to the dedicated clearance workspace.
class ClearancePreviewSection extends ConsumerWidget {
  const ClearancePreviewSection({super.key});

  void _showAddDebtDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddDebtDialog(
        onAddConfirmed: (creditor, total, paid, dueDate) {
          ref
              .read(clearanceControllerProvider.notifier)
              .addDebt(
                creditor: creditor,
                totalOwed: total,
                initialPaid: paid,
                dueDate: dueDate,
              );
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

    final clearedCount = debts.where((d) => d.isCleared).length;
    final pendingCount = debts.where((d) => !d.isCleared).length;
    final activeDebts = debts.where((d) => !d.isCleared).toList();
    final clearedDebts = debts.where((d) => d.isCleared).toList();
    final previewActive = activeDebts.take(3).toList();

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
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '$pendingCount active liabilities • $clearedCount settled',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (debts.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => context.go(Routes.clearance),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text('View Hub (${debts.length})'),
                    style: TextButton.styleFrom(
                      foregroundColor: brandColors.debt,
                    ),
                  ),
                  AppSpacing.hXS,
                ],
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
                'No pending debts or active liabilities. Log any loans or credit balances to start monitoring your burn-down trajectory.',
            actionLabel: 'Log First Debt Account',
            onAction: () => _showAddDebtDialog(context, ref),
          )
        else ...[
          for (final debt in previewActive)
            Padding(
              key: ValueKey(debt.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: DebtCard(
                debt: debt,
                onLogPayment: (amount) {
                  clearanceNotifier.logPayment(debt.id, amount);
                  dashboardNotifier.deductCash(amount);
                },
                onToggleCleared: () =>
                    clearanceNotifier.toggleCleared(debt.id),
                onDelete: () => clearanceNotifier.deleteDebt(debt.id),
              ),
            ),
          if (activeDebts.length > 3)
            InkWell(
              onTap: () => context.go(Routes.clearance),
              borderRadius: AppBorderRadius.allM,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: brandColors.subtle,
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.debt.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 16, color: brandColors.debt),
                    AppSpacing.hS,
                    Text(
                      '+ ${activeDebts.length - 3} more active accounts • Open Clearance Hub',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: brandColors.debt,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (clearedDebts.isNotEmpty) ...[
            AppSpacing.vS,
            InkWell(
              onTap: () => context.go(Routes.clearance),
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
                    Icon(Icons.task_alt_rounded,
                        size: 16, color: brandColors.progress),
                    AppSpacing.hS,
                    Expanded(
                      child: Text(
                        '$clearedCount settled accounts sunken below view',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: brandColors.progress,
                          fontWeight: AppFontWeight.semiBold,
                        ),
                      ),
                    ),
                    Text(
                      'View all →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: brandColors.progress,
                        fontWeight: AppFontWeight.bold,
                      ),
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
