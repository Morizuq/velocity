import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../shared/design_system/tokens/velocity_icon.dart';
import '../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../shared/design_system/theme/circular_theme_reveal.dart';
import '../../assets/presentation/widgets/asset_velocity_tracker.dart';
import '../../auth/presentation/widgets/user_profile_pill.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../../clearance/presentation/widgets/add_debt_dialog.dart';
import '../../clearance/presentation/widgets/debt_card.dart';
import '../../milestones/presentation/controllers/milestones_controller.dart';
import '../../milestones/presentation/widgets/add_milestone_dialog.dart';
import '../../milestones/presentation/widgets/milestone_card.dart';
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

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddMilestoneDialog(
        onAddConfirmed: (title, target, initial) {
          ref
              .read(milestonesControllerProvider.notifier)
              .addMilestone(
                title: title,
                targetAmount: target,
                initialAmount: initial,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final liquidCash = ref.watch(dashboardControllerProvider);
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

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
              LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompact = headerConstraints.maxWidth < 440;
                  final isVeryCompact = headerConstraints.maxWidth < 360;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const VelocityIcon(height: 28),
                            AppSpacing.hS,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'VELOCITY',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: AppFontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (!isVeryCompact)
                                    Text(
                                      isCompact
                                          ? 'Wealth Trajectory'
                                          : 'Financial Trajectory & Wealth Dashboard',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hS,
                      // Google Auth Profile Pill / Login CTA
                      const UserProfilePill(),
                      AppSpacing.hS,
                      // Theme Mode Pill Toggle with Circular Cascade Reveal
                      Builder(
                        builder: (btnContext) {
                          return Material(
                            color: Colors.transparent,
                            borderRadius: AppBorderRadius.pill,
                            child: InkWell(
                              onTap: () {
                                final renderBox =
                                    btnContext.findRenderObject() as RenderBox?;
                                final focalPoint =
                                    renderBox != null && renderBox.hasSize
                                    ? renderBox.localToGlobal(
                                        renderBox.size.center(Offset.zero),
                                      )
                                    : null;

                                final reveal = CircularThemeReveal.of(
                                  btnContext,
                                );
                                if (reveal != null) {
                                  reveal.toggleTheme(focalPoint: focalPoint);
                                } else {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .toggleTheme();
                                }
                              },
                              borderRadius: AppBorderRadius.pill,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact
                                      ? AppSpacing.s + 2
                                      : AppSpacing.m,
                                  vertical: AppSpacing.s - 2,
                                ),
                                decoration: BoxDecoration(
                                  color: brandColors.surfaceCard,
                                  borderRadius: AppBorderRadius.pill,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : const Color(0x06000000),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          RotationTransition(
                                            turns: anim,
                                            child: FadeTransition(
                                              opacity: anim,
                                              child: child,
                                            ),
                                          ),
                                      child: Icon(
                                        isDark
                                            ? Icons.light_mode_rounded
                                            : Icons.dark_mode_rounded,
                                        key: ValueKey<bool>(isDark),
                                        size: AppIconSize.s - 2,
                                        color: brandColors.accent,
                                      ),
                                    ),
                                    if (!isCompact) ...[
                                      AppSpacing.hS,
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: Text(
                                          isDark ? 'LIGHT' : 'DARK',
                                          key: ValueKey<bool>(isDark),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: AppFontWeight.bold,
                                                letterSpacing: 0.8,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              AppSpacing.vL,

              // Top Overarching Asset Horizon Tracker
              const AssetVelocityTracker(),
              AppSpacing.vL,

              // Four Key Metric KPI Cards (strictly hugging intrinsic content height)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 550 && !isWide;

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
                            Expanded(child: milestonesCard),
                            AppSpacing.hM,
                            Expanded(child: netPositionCard),
                          ],
                        ),
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
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
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
                    label: const Text(
                      'Add Debt',
                      style: TextStyle(fontSize: 12),
                    ),
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

              // Debt Cards Grid or Empty State
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    final double cardWidth = isWide
                        ? (constraints.maxWidth - AppSpacing.m) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.m,
                      children: debts.map((debt) {
                        return SizedBox(
                          width: cardWidth,
                          child: DebtCard(
                            debt: debt,
                            onLogPayment: (amount) {
                              clearanceNotifier.logPayment(debt.id, amount);
                              dashboardNotifier.deductCash(amount);
                            },
                            onToggleCleared: () =>
                                clearanceNotifier.toggleCleared(debt.id),
                            onDelete: () =>
                                clearanceNotifier.deleteDebt(debt.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              AppSpacing.vXL,

              // The Milestone Bucket (Upcoming Big Purchases)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Milestone Bucket',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.vXXS,
                        Text(
                          '${milestones.where((m) => m.isCompleted).length} of ${milestones.length} fulfilled goals',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hS,
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddMilestoneDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Goal',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColors.subtle,
                      foregroundColor: brandColors.milestone,
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

              // Milestone Cards Grid or Empty State
              if (milestones.isEmpty)
                VelocityEmptyStateCard(
                  icon: Icons.flag_rounded,
                  iconColor: brandColors.milestone,
                  badgeLabel: 'SAVINGS TARGETS',
                  badgeColor: brandColors.milestone,
                  title: 'No Milestone Buckets Created',
                  description:
                      'Define dedicated savings targets for upcoming big purchases (e.g. Rent, Workstation, Vacations) to focus your capital velocity.',
                  actionLabel: 'Create First Milestone Goal',
                  onAction: () => _showAddMilestoneDialog(context, ref),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    final double cardWidth = isWide
                        ? (constraints.maxWidth - AppSpacing.m) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.m,
                      children: milestones.map((milestone) {
                        return SizedBox(
                          width: cardWidth,
                          child: MilestoneCard(
                            milestone: milestone,
                            onAdjustDelta: (delta) {
                              milestonesNotifier.adjustFunds(
                                milestone.id,
                                delta,
                              );
                              if (delta > 0) {
                                dashboardNotifier.deductCash(delta);
                              } else {
                                dashboardNotifier.addIncome(delta.abs());
                              }
                            },
                            onSetExactTotal: (newTotal) {
                              final diff = newTotal - milestone.currentAmount;
                              milestonesNotifier.setMilestoneAmount(
                                milestone.id,
                                newTotal,
                              );
                              if (diff > 0) {
                                dashboardNotifier.deductCash(diff);
                              } else {
                                dashboardNotifier.addIncome(diff.abs());
                              }
                            },
                            onDelete: () => milestonesNotifier.deleteMilestone(
                              milestone.id,
                            ),
                          ),
                        );
                      }).toList(),
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
