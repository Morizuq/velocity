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
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';
import '../domain/entities/cashflow_direction.dart';
import 'controllers/recurring_cashflow_controller.dart';
import 'widgets/add_recurring_cashflow_dialog.dart';
import 'widgets/recurring_cashflow_card.dart';

/// Full-screen workspace page managing fixed subscriptions, living costs, and monthly cash flow cadence.
class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  int _selectedFilterIndex = 0;

  void _showAddDialog(BuildContext context, [CashflowDirection? direction]) {
    showDialog(
      context: context,
      builder: (ctx) => AddRecurringCashflowDialog(
        initialDirection: direction,
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
    final allItems = ref.watch(recurringCashflowControllerProvider);
    final monthlyOutflow = ref.watch(monthlyOutflowTotalProvider);
    final monthlyInflow = ref.watch(monthlyInflowTotalProvider);
    final netCashflow = ref.watch(netMonthlyCashflowProvider);
    final runway = ref.watch(cashRunwayMonthsProvider);

    final controller = ref.read(
      recurringCashflowControllerProvider.notifier,
    );
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    // Filter items
    final filteredItems = allItems.where((item) {
      switch (_selectedFilterIndex) {
        case 1:
          return item.direction == CashflowDirection.outflowPayable;
        case 2:
          return item.direction == CashflowDirection.inflowReceivable;
        case 3:
          return !item.isSettledThisMonth;
        case 4:
          return item.isSettledThisMonth;
        default:
          return true;
      }
    }).toList();

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
                          'Expenses & Cash Flow',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          'Track fixed subscriptions, living costs, salary, and recurring runway.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hM,
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Commitment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColors.accent,
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
              AppSpacing.vL,

              // Top Metric KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 950;
                  final isMedium = constraints.maxWidth >= 550 && !isWide;

                  final burnCard = VelocityMetricCard(
                    title: 'Fixed Monthly Outflow',
                    value: FinancialNumberFormatter.format(monthlyOutflow),
                    subtitle: 'Subscriptions & Living Costs',
                    icon: Icons.calendar_month_rounded,
                    accentColor: brandColors.debt,
                  );

                  final inflowCard = VelocityMetricCard(
                    title: 'Fixed Monthly Inflow',
                    value: FinancialNumberFormatter.format(monthlyInflow),
                    subtitle: 'Salary & Recurring Retainers',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: brandColors.progress,
                  );

                  final marginCard = VelocityMetricCard(
                    title: 'Net Monthly Margin',
                    value: '${netCashflow >= 0 ? '+' : ''}${FinancialNumberFormatter.format(netCashflow)}',
                    subtitle: netCashflow >= 0
                        ? 'Monthly Cash Surplus'
                        : 'Monthly Cash Deficit',
                    icon: Icons.trending_up_rounded,
                    accentColor: netCashflow >= 0
                        ? brandColors.progress
                        : brandColors.debt,
                  );

                  final runwayCard = VelocityMetricCard(
                    title: 'Cash Runway',
                    value: runway.isInfinite
                        ? '∞ Months'
                        : '${runway.toStringAsFixed(1)} Months',
                    subtitle: runway.isInfinite
                        ? 'Surplus Operating Margin'
                        : 'Until Liquidity Depletion',
                    icon: Icons.flight_takeoff_rounded,
                    accentColor: runway.isInfinite || runway >= 6
                        ? brandColors.progress
                        : brandColors.receivable,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: burnCard),
                        AppSpacing.hM,
                        Expanded(child: inflowCard),
                        AppSpacing.hM,
                        Expanded(child: marginCard),
                        AppSpacing.hM,
                        Expanded(child: runwayCard),
                      ],
                    );
                  }

                  if (isMedium) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: burnCard),
                            AppSpacing.hM,
                            Expanded(child: inflowCard),
                          ],
                        ),
                        AppSpacing.vM,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: marginCard),
                            AppSpacing.hM,
                            Expanded(child: runwayCard),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      burnCard,
                      AppSpacing.vM,
                      inflowCard,
                      AppSpacing.vM,
                      marginCard,
                      AppSpacing.vM,
                      runwayCard,
                    ],
                  );
                },
              ),
              AppSpacing.vL,

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All (${allItems.length})'),
                    AppSpacing.hS,
                    _buildFilterChip(1, 'Subscriptions & Bills'),
                    AppSpacing.hS,
                    _buildFilterChip(2, 'Salary & Retainers'),
                    AppSpacing.hS,
                    _buildFilterChip(
                      3,
                      'Pending Cycle (${allItems.where((i) => !i.isSettledThisMonth).length})',
                    ),
                    AppSpacing.hS,
                    _buildFilterChip(
                      4,
                      'Settled Cycle (${allItems.where((i) => i.isSettledThisMonth).length})',
                    ),
                  ],
                ),
              ),
              AppSpacing.vL,

              // Cash flow List or Empty State
              if (filteredItems.isEmpty)
                VelocityEmptyStateCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: brandColors.accent,
                  badgeLabel: 'CADENCE EMPTY',
                  badgeColor: brandColors.accent,
                  title: 'No Recurring Commitments',
                  description:
                      'Track recurring payables (Internet, Spotify, Rent) and fixed income (Salary, Retainers) to monitor your cash burn rate and runway.',
                  actionLabel: 'Log First Recurring Item',
                  onAction: () => _showAddDialog(context),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: filteredItems.length,
                  onReorder: (oldIndex, newIndex) {
                    final movedItem = filteredItems[oldIndex];
                    final fullOldIndex = allItems.indexOf(movedItem);
                    final fullNewIndex = newIndex < filteredItems.length
                        ? allItems.indexOf(filteredItems[newIndex])
                        : allItems.length;
                    controller.reorderCashflows(fullOldIndex, fullNewIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: RecurringCashflowCard(
                        cashflow: item,
                        dragHandle: ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
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
                          controller.toggleSettledCurrentCycle(item.id);
                          if (!wasSettled) {
                            if (item.direction ==
                                CashflowDirection.outflowPayable) {
                              dashboardNotifier.deductCash(item.amount);
                            } else {
                              dashboardNotifier.addIncome(item.amount);
                            }
                          } else {
                            // Reverse the adjustment
                            if (item.direction ==
                                CashflowDirection.outflowPayable) {
                              dashboardNotifier.addIncome(item.amount);
                            } else {
                              dashboardNotifier.deductCash(item.amount);
                            }
                          }
                        },
                        onDelete: () => controller.deleteCashflow(item.id),
                      ),
                    );
                  },
                ),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final brandColors = context.brandColors;

    return VelocityPillFilter(
      label: label,
      isSelected: isSelected,
      activeColor: brandColors.accent,
      onTap: () => setState(() => _selectedFilterIndex = index),
    );
  }
}
