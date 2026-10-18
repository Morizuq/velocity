import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../dashboard/presentation/widgets/debt_burndown_chart.dart';
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';
import 'controllers/clearance_controller.dart';
import 'widgets/add_debt_dialog.dart';
import 'widgets/clearance_bucket_section.dart';

/// Full-screen dedicated workspace for managing all clearance debt accounts,
/// burn-down trajectory, due dates, and settlement history.
class ClearancePage extends ConsumerWidget {
  const ClearancePage({super.key});

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
    final totalRemaining = ref.watch(totalClearanceDebtProvider);
    final totalOriginal = ref.watch(totalOriginalDebtProvider);
    final totalPaid = ref.watch(totalDebtPaidProvider);

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
                          'Track, prioritize, and liquidate liabilities with tactical velocity.',
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
                    onPressed: () => _showAddDebtDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Debt Account'),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColors.debt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                    ),
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
                    title: 'Active Remaining Due',
                    value: FinancialNumberFormatter.format(totalRemaining),
                    subtitle: '$pendingCount Active Accounts',
                    icon: Icons.money_off_rounded,
                    accentColor: brandColors.debt,
                  );

                  final paidCard = VelocityMetricCard(
                    title: 'Total Debt Paid',
                    value: FinancialNumberFormatter.format(totalPaid),
                    subtitle: '$clearedCount Cleared Accounts',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: brandColors.progress,
                  );

                  final totalCard = VelocityMetricCard(
                    title: 'Total Initial Liabilities',
                    value: FinancialNumberFormatter.format(totalOriginal),
                    subtitle: 'Original baseline owed',
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: brandColors.milestone,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: remainingCard),
                        AppSpacing.hM,
                        Expanded(child: paidCard),
                        AppSpacing.hM,
                        Expanded(child: totalCard),
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
                            Expanded(child: paidCard),
                          ],
                        ),
                        AppSpacing.vM,
                        totalCard,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      remainingCard,
                      AppSpacing.vM,
                      paidCard,
                      AppSpacing.vM,
                      totalCard,
                    ],
                  );
                },
              ),
              AppSpacing.vXL,

              // Visual Debt Burn-Down Chart
              const DebtBurndownChart(),
              AppSpacing.vXL,

              // Full Workspace Clearance List (Full Mode)
              const ClearanceBucketSection(),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }
}
