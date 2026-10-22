import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/cashflow_direction.dart';
import '../controllers/recurring_cashflow_controller.dart';
import 'add_recurring_cashflow_dialog.dart';
import 'recurring_cashflow_card.dart';

/// Executive dashboard preview section showing upcoming recurring monthly bills
/// (Spotify, Internet, Cloud) and salaries, with direct actions to record new subscriptions.
class ExpensesPreviewSection extends ConsumerWidget {
  const ExpensesPreviewSection({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddRecurringCashflowDialog(
        initialDirection: CashflowDirection.outflowPayable,
        onAddConfirmed:
            ({
              required title,
              required amount,
              required direction,
              required dayOfMonth,
              required category,
              endDate,
              notes,
            }) {
              ref
                  .read(recurringCashflowControllerProvider.notifier)
                  .addCashflow(
                    title: title,
                    amount: amount,
                    direction: direction,
                    dayOfMonth: dayOfMonth,
                    category: category,
                    endDate: endDate,
                    notes: notes,
                  );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final allCashflows = ref.watch(recurringCashflowControllerProvider);
    final monthlyOutflow = ref.watch(monthlyOutflowTotalProvider);
    final monthlyInflow = ref.watch(monthlyInflowTotalProvider);
    final controller = ref.read(recurringCashflowControllerProvider.notifier);
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    final pendingOutflows = allCashflows
        .where(
          (i) =>
              i.direction == CashflowDirection.outflowPayable &&
              !i.isSettledThisMonth,
        )
        .toList();
    final activeOutflows = allCashflows
        .where((i) => i.direction == CashflowDirection.outflowPayable)
        .toList();
    final previewItems = activeOutflows.take(3).toList();

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
                    'Monthly Subscriptions & Living Costs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '${FinancialNumberFormatter.format(monthlyOutflow)}/mo Burn • ${FinancialNumberFormatter.format(monthlyInflow)}/mo Fixed Inflow • ${pendingOutflows.length} pending this month',
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
                if (allCashflows.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => context.go(Routes.expenses),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text('View Hub (${allCashflows.length})'),
                    style: TextButton.styleFrom(
                      foregroundColor: brandColors.accent,
                    ),
                  ),
                  AppSpacing.hXS,
                ],
                FilledButton.tonalIcon(
                  onPressed: () => _showAddDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Subscription',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColors.subtle,
                    foregroundColor: brandColors.accent,
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
        if (activeOutflows.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.calendar_month_rounded,
            iconColor: brandColors.accent,
            badgeLabel: 'NO SUBSCRIPTIONS',
            badgeColor: brandColors.accent,
            title: 'Track Spotify, Internet & Fixed Bills',
            description:
                'Log your monthly recurring payables like Spotify, WiFi, cloud hosting, and rent to monitor your burn rate and runway without skewing finite debt metrics.',
            actionLabel: 'Add First Subscription / Bill',
            onAction: () => _showAddDialog(context, ref),
          )
        else ...[
          for (final item in previewItems)
            Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: RecurringCashflowCard(
                cashflow: item,
                onToggleSettledCurrentCycle: () {
                  final wasSettled = item.isSettledThisMonth;
                  controller.toggleSettledCurrentCycle(item.id);
                  if (!wasSettled) {
                    if (item.direction == CashflowDirection.outflowPayable) {
                      dashboardNotifier.deductCash(item.amount);
                    } else {
                      dashboardNotifier.addIncome(item.amount);
                    }
                  } else {
                    if (item.direction == CashflowDirection.outflowPayable) {
                      dashboardNotifier.addIncome(item.amount);
                    } else {
                      dashboardNotifier.deductCash(item.amount);
                    }
                  }
                },
                onDelete: () => controller.deleteCashflow(item.id),
              ),
            ),
          if (activeOutflows.length > 3)
            InkWell(
              onTap: () => context.go(Routes.expenses),
              borderRadius: AppBorderRadius.allM,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: brandColors.subtle,
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: brandColors.accent,
                    ),
                    AppSpacing.hS,
                    Text(
                      '+ ${activeOutflows.length - 3} more monthly commitments • Open Expenses Hub',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: brandColors.accent,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
