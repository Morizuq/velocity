import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_border_width.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../assets/presentation/widgets/asset_velocity_tracker.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../../clearance/presentation/widgets/debt_card.dart';
import '../../milestones/presentation/controllers/milestones_controller.dart';
import '../../milestones/presentation/widgets/milestone_card.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/debt_burndown_chart.dart';
import 'widgets/financial_velocity_donut_chart.dart';
import 'widgets/velocity_metric_card.dart';

/// The central executive dashboard page orchestrating Clearance, Milestones, and Asset metrics.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final liquidCash = ref.watch(dashboardControllerProvider);
    final totalDebt = ref.watch(totalClearanceDebtProvider);
    final totalMilestonesSaved = ref.watch(totalMilestoneSavedProvider);
    final netVelocity = liquidCash - totalDebt;

    final debts = ref.watch(clearanceControllerProvider);
    final clearanceNotifier = ref.read(clearanceControllerProvider.notifier);

    final milestones = ref.watch(milestonesControllerProvider);
    final milestonesNotifier = ref.read(milestonesControllerProvider.notifier);

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
              // Top Header Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandColors.mid, brandColors.accent],
                          ),
                          borderRadius: AppBorderRadius.allM,
                          boxShadow: [
                            BoxShadow(
                              color: brandColors.mid.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('⚡', style: TextStyle(fontSize: 22)),
                      ),
                      AppSpacing.hM,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VELOCITY',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: AppFontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Financial Trajectory & Wealth Dashboard',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Theme Mode Pill Toggle
                  InkWell(
                    onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                    borderRadius: AppBorderRadius.pill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      decoration: BoxDecoration(
                        color: brandColors.surfaceCard,
                        borderRadius: AppBorderRadius.pill,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: AppIconSize.s,
                            color: brandColors.accent,
                          ),
                          AppSpacing.hS,
                          Text(
                            isDark ? 'LIGHT' : 'DARK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vXL,

              // Top Overarching Asset Horizon Tracker
              const AssetVelocityTracker(),
              AppSpacing.vXL,

              // Four Key Metric KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 550 && !isWide;

                  return GridView.count(
                    crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.m,
                    mainAxisSpacing: AppSpacing.m,
                    childAspectRatio: isWide ? 1.6 : 2.2,
                    children: [
                      VelocityMetricCard(
                        title: 'Total Liquid Cash',
                        value: FinancialNumberFormatter.format(liquidCash),
                        subtitle: 'Readily Available',
                        icon: Icons.account_balance_rounded,
                        accentColor: brandColors.progress,
                      ),
                      VelocityMetricCard(
                        title: 'Clearance Debt',
                        value: FinancialNumberFormatter.format(totalDebt),
                        subtitle: '${debts.where((d) => !d.isCleared).length} Pending Dues',
                        icon: Icons.credit_card_off_rounded,
                        accentColor: brandColors.debt,
                      ),
                      VelocityMetricCard(
                        title: 'Milestones Saved',
                        value: FinancialNumberFormatter.format(totalMilestonesSaved),
                        subtitle: '${milestones.where((m) => m.isCompleted).length} Goals Completed',
                        icon: Icons.emoji_events_rounded,
                        accentColor: brandColors.milestone,
                      ),
                      VelocityMetricCard(
                        title: 'Net Velocity Position',
                        value: FinancialNumberFormatter.format(netVelocity),
                        subtitle: 'Cash minus Debt',
                        icon: Icons.speed_rounded,
                        accentColor: netVelocity >= 0 ? brandColors.accent : brandColors.debt,
                      ),
                    ],
                  );
                },
              ),
              AppSpacing.vXL,

              // Analytics Section: Donut Chart & Debt Burn-down Line Chart
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;
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
                        const Expanded(
                          flex: 6,
                          child: DebtBurndownChart(),
                        ),
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
              AppSpacing.vXXL,

              // The Clearance Bucket (Debts & Immediate Dues)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Clearance Bucket',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        'Immediate dues and debt clearance tracker',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${debts.where((d) => d.isCleared).length} of ${debts.length} cleared',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: brandColors.progress,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.vL,

              // Debt Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  return GridView.builder(
                    itemCount: debts.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: AppSpacing.m,
                      mainAxisSpacing: AppSpacing.m,
                      childAspectRatio: isWide ? 1.7 : 1.6,
                    ),
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      return DebtCard(
                        debt: debt,
                        onLogPayment: (amount) {
                          clearanceNotifier.logPayment(debt.id, amount);
                          ref.read(dashboardControllerProvider.notifier).deductCash(amount);
                        },
                        onToggleCleared: () => clearanceNotifier.toggleCleared(debt.id),
                      );
                    },
                  );
                },
              ),
              AppSpacing.vXXL,

              // The Milestone Bucket (Upcoming Big Purchases)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Milestone Bucket',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        'Target savings for planned acquisitions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${milestones.where((m) => m.isCompleted).length} of ${milestones.length} fulfilled',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: brandColors.milestone,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.vL,

              // Milestone Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 768;
                  return GridView.builder(
                    itemCount: milestones.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: AppSpacing.m,
                      mainAxisSpacing: AppSpacing.m,
                      childAspectRatio: isWide ? 1.7 : 1.6,
                    ),
                    itemBuilder: (context, index) {
                      final milestone = milestones[index];
                      return MilestoneCard(
                        milestone: milestone,
                        onFundMilestone: (amount) {
                          milestonesNotifier.allocateFunds(milestone.id, amount);
                          ref.read(dashboardControllerProvider.notifier).deductCash(amount);
                        },
                      );
                    },
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
}
