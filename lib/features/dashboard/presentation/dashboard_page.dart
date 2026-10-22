import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../assets/presentation/widgets/asset_velocity_tracker.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../../clearance/presentation/widgets/clearance_preview_section.dart';
import '../../expenses/presentation/widgets/expenses_preview_section.dart';
import '../../milestones/presentation/controllers/milestones_controller.dart';
import '../../milestones/presentation/widgets/milestones_bucket_section.dart';
import '../../receivables/presentation/controllers/receivables_controller.dart';
import '../../receivables/presentation/widgets/receivables_preview_section.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/debt_burndown_chart.dart';
import 'widgets/financial_velocity_donut_chart.dart';
import 'widgets/update_liquid_cash_dialog.dart';
import 'widgets/velocity_metric_card.dart';

/// The central executive dashboard page orchestrating Clearance, Milestones, and Asset metrics.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  void _showUpdateLiquidCashDialog(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => UpdateLiquidCashDialog(
        currentBalance: current,
        onBalanceConfirmed: (newBalance) {
          ref
              .read(dashboardControllerProvider.notifier)
              .updateLiquidCash(newBalance);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final liquidCash = ref.watch(dashboardControllerProvider);
    final totalDebt = ref.watch(totalClearanceDebtProvider);
    final totalReceivables = ref.watch(totalReceivablesProvider);
    final totalMilestonesSaved = ref.watch(totalMilestoneSavedProvider);
    final debts = ref.watch(clearanceControllerProvider);
    final receivables = ref.watch(receivablesControllerProvider);
    final milestones = ref.watch(milestonesControllerProvider);
    final netVelocity = liquidCash - totalDebt;

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
              // Top Overarching Asset Horizon Tracker
              const AssetVelocityTracker(),
              AppSpacing.vL,

              // Key Metric KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;
                  final isMedium = constraints.maxWidth >= 600 && !isWide;

                  final liquidCashCard = VelocityMetricCard(
                    title: 'Total Liquid Cash',
                    value: FinancialNumberFormatter.format(liquidCash),
                    subtitle: liquidCash > 0
                        ? 'Tap to Adjust Cash'
                        : 'Tap to Enter Cash',
                    icon: Icons.account_balance_rounded,
                    accentColor: brandColors.progress,
                    onTap: () =>
                        _showUpdateLiquidCashDialog(context, ref, liquidCash),
                  );

                  final debtCard = VelocityMetricCard(
                    title: 'Clearance Debt',
                    value: FinancialNumberFormatter.format(totalDebt),
                    subtitle:
                        '${debts.where((d) => !d.isCleared).length} Pending Accounts',
                    icon: Icons.credit_card_off_rounded,
                    accentColor: brandColors.debt,
                  );

                  final receivablesCard = VelocityMetricCard(
                    title: 'Pending Receivables',
                    value: FinancialNumberFormatter.format(totalReceivables),
                    subtitle:
                        '${receivables.where((r) => !r.isSettled).length} Inflow Claims',
                    icon: Icons.hourglass_top_rounded,
                    accentColor: brandColors.receivable,
                  );

                  final milestonesCard = VelocityMetricCard(
                    title: 'Milestones Saved',
                    value: FinancialNumberFormatter.format(
                      totalMilestonesSaved,
                    ),
                    subtitle:
                        '${milestones.where((m) => m.isCompleted).length} Completed',
                    icon: Icons.emoji_events_rounded,
                    accentColor: brandColors.milestone,
                  );

                  final netPositionCard = VelocityMetricCard(
                    title: 'Net Velocity Position',
                    value: FinancialNumberFormatter.format(netVelocity),
                    subtitle: 'Cash minus Debt',
                    icon: Icons.speed_rounded,
                    accentColor: netVelocity >= 0
                        ? brandColors.accent
                        : brandColors.debt,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: liquidCashCard),
                        AppSpacing.hM,
                        Expanded(child: debtCard),
                        AppSpacing.hM,
                        Expanded(child: receivablesCard),
                        AppSpacing.hM,
                        Expanded(child: milestonesCard),
                        AppSpacing.hM,
                        Expanded(child: netPositionCard),
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
                            Expanded(child: liquidCashCard),
                            AppSpacing.hM,
                            Expanded(child: debtCard),
                          ],
                        ),
                        AppSpacing.vM,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: receivablesCard),
                            AppSpacing.hM,
                            Expanded(child: milestonesCard),
                          ],
                        ),
                        AppSpacing.vM,
                        netPositionCard,
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      liquidCashCard,
                      AppSpacing.vM,
                      debtCard,
                      AppSpacing.vM,
                      receivablesCard,
                      AppSpacing.vM,
                      milestonesCard,
                      AppSpacing.vM,
                      netPositionCard,
                    ],
                  );
                },
              ),
              AppSpacing.vL,

              // Analytics Section: Donut Chart & Debt Burn-down Line Chart
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 980;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: FinancialVelocityDonutChart(
                            totalLiquidCash: liquidCash,
                          ),
                        ),
                        AppSpacing.hL,
                        const Expanded(flex: 6, child: DebtBurndownChart()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      FinancialVelocityDonutChart(totalLiquidCash: liquidCash),
                      AppSpacing.vL,
                      const DebtBurndownChart(),
                    ],
                  );
                },
              ),
              AppSpacing.vXL,

              // The Clearance Bucket (Debts & Immediate Dues)
              const ClearancePreviewSection(),
              AppSpacing.vXL,

              // The Receivables Bucket (Freelance Invoices & Loans)
              const ReceivablesPreviewSection(),
              AppSpacing.vXL,

              // Monthly Operating Cadence (Subscriptions, Spotify, Internet & Living Costs)
              const ExpensesPreviewSection(),
              AppSpacing.vXL,

              // The Milestone Bucket (Upcoming Big Purchases)
              const MilestonesBucketSection(),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }
}
