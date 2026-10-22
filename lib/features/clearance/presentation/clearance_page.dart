import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/buttons/velocity_pill_filter.dart';
import '../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../dashboard/presentation/widgets/debt_burndown_chart.dart';
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';
import '../../expenses/domain/entities/cashflow_direction.dart';
import '../../expenses/presentation/controllers/recurring_cashflow_controller.dart';
import '../../expenses/presentation/widgets/add_recurring_cashflow_dialog.dart';
import '../../expenses/presentation/widgets/recurring_cashflow_card.dart';
import 'controllers/clearance_controller.dart';
import 'widgets/add_debt_dialog.dart';
import 'widgets/clearance_bucket_section.dart';

/// Full-screen dedicated workspace for managing all clearance liabilities,
/// supporting both term debt accounts and recurring monthly bills (Spotify, Internet, Rent).
class ClearancePage extends ConsumerStatefulWidget {
  const ClearancePage({super.key});

  @override
  ConsumerState<ClearancePage> createState() => _ClearancePageState();
}

class _ClearancePageState extends ConsumerState<ClearancePage> {
  int _selectedTab = 0; // 0 = Term Debts, 1 = Monthly Bills & Subscriptions

  void _showAddDebtDialog(BuildContext context) {
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

  void _showAddMonthlyBillDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddRecurringCashflowDialog(
        initialDirection: CashflowDirection.outflowPayable,
        onAddConfirmed: ({
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final debts = ref.watch(clearanceControllerProvider);
    final totalRemaining = ref.watch(totalClearanceDebtProvider);
    final totalOriginal = ref.watch(totalOriginalDebtProvider);
    final totalPaid = ref.watch(totalDebtPaidProvider);

    final monthlyBills = ref.watch(monthlyOutflowsProvider);
    final totalMonthlyBills = ref.watch(monthlyOutflowTotalProvider);
    final cashflowController = ref.read(
      recurringCashflowControllerProvider.notifier,
    );
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    final clearedCount = debts.where((d) => d.isCleared).length;
    final pendingCount = debts.where((d) => !d.isCleared).length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSpacing.m,
              tablet: AppSpacing.xl,
              desktop: AppSpacing.xxl,
            ),
            vertical: AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clearance Hub',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          'Track term liabilities and monthly bills (Spotify, Internet, Utilities) with tactical velocity.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hM,
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.xs,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _showAddMonthlyBillDialog(context),
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: const Text('Add Monthly Bill'),
                        style: FilledButton.styleFrom(
                          backgroundColor: brandColors.subtle,
                          foregroundColor: brandColors.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.m,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppBorderRadius.pill,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showAddDebtDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Debt Account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: brandColors.debt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                            vertical: AppSpacing.m,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppBorderRadius.pill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.vL,

              // Clearance Metric Highlights
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 550 && !isWide;

                  final remainingCard = VelocityMetricCard(
                    title: 'Active Remaining Debt',
                    value: FinancialNumberFormatter.format(totalRemaining),
                    subtitle: '$pendingCount Active Debt Accounts',
                    icon: Icons.money_off_rounded,
                    accentColor: brandColors.debt,
                  );

                  final monthlyBillsCard = VelocityMetricCard(
                    title: 'Monthly Recurring Bills',
                    value: FinancialNumberFormatter.format(totalMonthlyBills),
                    subtitle:
                        '${monthlyBills.length} Subscriptions & Utilities',
                    icon: Icons.calendar_month_rounded,
                    accentColor: brandColors.accent,
                  );

                  final paidCard = VelocityMetricCard(
                    title: 'Total Debt Cleared',
                    value: FinancialNumberFormatter.format(totalPaid),
                    subtitle: '$clearedCount Cleared Accounts',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: brandColors.progress,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: remainingCard),
                        AppSpacing.hM,
                        Expanded(child: monthlyBillsCard),
                        AppSpacing.hM,
                        Expanded(child: paidCard),
                      ],
                    );
                  }

                  if (isMedium) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: remainingCard),
                            AppSpacing.hM,
                            Expanded(child: monthlyBillsCard),
                          ],
                        ),
                        AppSpacing.vM,
                        paidCard,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      remainingCard,
                      AppSpacing.vM,
                      monthlyBillsCard,
                      AppSpacing.vM,
                      paidCard,
                    ],
                  );
                },
              ),
              AppSpacing.vL,

              // Segmented Tabs: Term Debts vs Monthly Subscriptions & Bills
              Row(
                children: [
                  VelocityPillFilter(
                    label: 'Term Debts (${debts.length})',
                    isSelected: _selectedTab == 0,
                    activeColor: brandColors.debt,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  AppSpacing.hS,
                  VelocityPillFilter(
                    label: 'Monthly Bills & Subscriptions (${monthlyBills.length})',
                    isSelected: _selectedTab == 1,
                    activeColor: brandColors.accent,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
              AppSpacing.vL,

              if (_selectedTab == 0) ...[
                // Visual Debt Burn-Down Chart
                const DebtBurndownChart(),
                AppSpacing.vXL,

                // Full Workspace Clearance List (Full Mode)
                const ClearanceBucketSection(),
              ] else ...[
                // Monthly Bills List (Spotify, Internet, Rent)
                if (monthlyBills.isEmpty)
                  VelocityEmptyStateCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: brandColors.accent,
                    badgeLabel: 'NO MONTHLY BILLS',
                    badgeColor: brandColors.accent,
                    title: 'No Recurring Bills Logged',
                    description:
                        'Add your monthly subscriptions and operating expenses like Spotify, Internet, utilities, or rent to track what is due every cycle.',
                    actionLabel: 'Add Spotify / Internet / Bill',
                    onAction: () => _showAddMonthlyBillDialog(context),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: monthlyBills.length,
                    onReorder: (oldIndex, newIndex) {
                      final item = monthlyBills[oldIndex];
                      final fullItems = ref.read(
                        recurringCashflowControllerProvider,
                      );
                      final fullOldIndex = fullItems.indexOf(item);
                      final fullNewIndex = newIndex < monthlyBills.length
                          ? fullItems.indexOf(monthlyBills[newIndex])
                          : fullItems.length;
                      cashflowController.reorderCashflows(
                        fullOldIndex,
                        fullNewIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = monthlyBills[index];
                      return Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: RecurringCashflowCard(
                          cashflow: item,
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          onToggleSettledCurrentCycle: () {
                            final wasSettled = item.isSettledThisMonth;
                            cashflowController.toggleSettledCurrentCycle(
                              item.id,
                            );
                            if (!wasSettled) {
                              dashboardNotifier.deductCash(item.amount);
                            } else {
                              dashboardNotifier.addIncome(item.amount);
                            }
                          },
                          onDelete: () =>
                              cashflowController.deleteCashflow(item.id),
                        ),
                      );
                    },
                  ),
              ],
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }
}
