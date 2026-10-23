import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../shared/design_system/layout/velocity_scaffold.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../shared/design_system/widgets/velocity_card.dart';
import '../../../shared/design_system/widgets/velocity_progress_bar.dart';
import '../../../shared/design_system/widgets/velocity_tag.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../../expenses/presentation/controllers/recurring_cashflow_controller.dart';
import '../../receivables/presentation/controllers/receivables_controller.dart';
import 'widgets/velocity_donut_chart.dart';
import 'widgets/velocity_horizontal_bars.dart';
import 'widgets/velocity_payoff_chart.dart';

/// Redesigned central executive dashboard page
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    // Data from controllers
    final incomeList = ref.watch(monthlyInflowsProvider);
    final expenseList = ref.watch(monthlyOutflowsProvider);
    final debts = ref.watch(clearanceControllerProvider);
    final receivables = ref.watch(receivablesControllerProvider);

    // Financial calculations matching reference
    final inc = incomeList.fold<double>(0.0, (s, x) => s + x.amount);
    final fixed = expenseList.fold<double>(0.0, (s, x) => s + x.amount);
    final dm = ref.watch(totalDebtMonthlyPaymentProvider);
    final free = inc - fixed - dm;
    final owe = debts
        .where((d) => !d.isCleared)
        .fold<double>(0.0, (s, x) => s + x.remainingAmount);
    final due = receivables
        .where((r) => !r.isSettled)
        .fold<double>(0.0, (s, x) => s + x.remainingBalance);
    final net = due - owe;

    final w = math.max(inc, fixed + dm);

    // Coming up: Next 5 debts & receivables with due dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_UpcomingItem> upcoming = [];
    for (final d in debts) {
      if (!d.isCleared && d.hasDueDate && d.remainingAmount > 0) {
        final amt = d.monthlyPayment > 0
            ? math.min(d.monthlyPayment, d.remainingAmount)
            : d.remainingAmount;
        upcoming.add(_UpcomingItem(
          title: 'Pay: ${d.creditor}',
          dueDate: d.dueDate!,
          amount: amt,
          isPay: true,
          isOverdue: d.dueDate!.isBefore(today),
        ));
      }
    }
    for (final r in receivables) {
      if (!r.isSettled && r.dueDate != null && r.remainingBalance > 0) {
        upcoming.add(_UpcomingItem(
          title: 'Collect: ${r.debtor}',
          dueDate: r.dueDate!,
          amount: r.remainingBalance,
          isPay: false,
          isOverdue: r.dueDate!.isBefore(today),
        ));
      }
    }
    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final soon = upcoming.take(5).toList();

    // Receivables by age
    final ageBins = [0.0, 0.0, 0.0, 0.0];
    for (final r in receivables) {
      if (r.isSettled || r.remainingBalance <= 0) continue;
      if (r.dueDate == null) {
        ageBins[0] += r.remainingBalance;
      } else {
        final days = today.difference(r.dueDate!).inDays;
        if (days <= 0) {
          ageBins[0] += r.remainingBalance;
        } else if (days <= 30) {
          ageBins[1] += r.remainingBalance;
        } else if (days <= 60) {
          ageBins[2] += r.remainingBalance;
        } else {
          ageBins[3] += r.remainingBalance;
        }
      }
    }

    // Recurring expenses donut slices
    final donutSlices = <VelocityDonutSlice>[];
    for (int i = 0; i < expenseList.length; i++) {
      final exp = expenseList[i];
      final color = tokens.chartCategories[i % tokens.chartCategories.length];
      donutSlices.add(VelocityDonutSlice(
        label: exp.title,
        amount: exp.amount,
        color: color,
      ));
    }

    return VelocityScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Card: Free Cash + Split Bar + Legend
          VelocityHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Left over each month after bills and debt payments',
                  style: tokens.figtree(
                    fontSize: 15,
                    color: tokens.muteColor,
                  ),
                ),
                AppSpacing.vXS,
                Text(
                  FinancialNumberFormatter.format(free),
                  style: tokens.bricolage(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: free < 0 ? tokens.outColor : tokens.inColor,
                  ),
                ),
                AppSpacing.vM,

                // Split Bar
                VelocitySplitBar(
                  total: w,
                  segments: [
                    if (w > 0 && fixed > 0)
                      VelocitySplitSegment(
                        value: fixed,
                        color: tokens.outColor,
                      ),
                    if (w > 0 && dm > 0)
                      VelocitySplitSegment(
                        value: dm,
                        color: tokens.owedColor,
                      ),
                    if (w > 0 && free > 0)
                      VelocitySplitSegment(
                        value: free,
                        color: tokens.inColor,
                      ),
                  ],
                ),
                AppSpacing.vS,

                  // Legend
                  Wrap(
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      _LegendItem(
                        color: tokens.outColor,
                        label: 'Recurring',
                        value: FinancialNumberFormatter.format(fixed),
                      ),
                      _LegendItem(
                        color: tokens.owedColor,
                        label: 'Debt payments',
                        value: FinancialNumberFormatter.format(dm),
                      ),
                      _LegendItem(
                        color: tokens.inColor,
                        label: 'Free',
                        value: FinancialNumberFormatter.format(math.max(0, free)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.vL,

            // 4 Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 540;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: AppSpacing.m,
                  mainAxisSpacing: AppSpacing.m,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.4 : 1.3,
                  children: [
                    _StatTile(
                      label: 'Monthly income',
                      value: FinancialNumberFormatter.format(inc),
                      color: tokens.inColor,
                    ),
                    _StatTile(
                      label: 'I owe',
                      value: FinancialNumberFormatter.format(owe),
                      color: tokens.outColor,
                    ),
                    _StatTile(
                      label: 'Owed to me',
                      value: FinancialNumberFormatter.format(due),
                      color: tokens.owedColor,
                    ),
                    _StatTile(
                      label: 'Net position',
                      value: FinancialNumberFormatter.format(net),
                      color: net < 0 ? tokens.outColor : tokens.inColor,
                    ),
                  ],
                );
              },
            ),
            AppSpacing.vXL,

            // 4 Charts Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VelocityCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Where income goes',
                                  style: tokens.bricolage(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.vS,
                                VelocityHorizontalBars(
                                  items: [
                                    VelocityHorizontalBarItem(
                                      label: 'Income',
                                      value: inc,
                                      color: tokens.inColor,
                                    ),
                                    VelocityHorizontalBarItem(
                                      label: 'Recurring',
                                      value: fixed,
                                      color: tokens.outColor,
                                    ),
                                    VelocityHorizontalBarItem(
                                      label: 'Debt payments',
                                      value: dm,
                                      color: tokens.owedColor,
                                    ),
                                    VelocityHorizontalBarItem(
                                      label: 'Free',
                                      value: math.max(0, free),
                                      color: tokens.accentColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isWide) AppSpacing.hS,
                        if (isWide)
                          Expanded(
                            child: VelocityCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recurring expenses',
                                    style: tokens.bricolage(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppSpacing.vS,
                                  VelocityDonutChart(slices: donutSlices),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!isWide) ...[
                      AppSpacing.vS,
                      VelocityCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring expenses',
                              style: tokens.bricolage(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppSpacing.vS,
                            VelocityDonutChart(slices: donutSlices),
                          ],
                        ),
                      ),
                    ],
                    AppSpacing.vS,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VelocityCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Debt balance, next 24 months',
                                  style: tokens.bricolage(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.vS,
                                VelocityPayoffChart(debts: debts),
                              ],
                            ),
                          ),
                        ),
                        if (isWide) AppSpacing.hS,
                        if (isWide)
                          Expanded(
                            child: VelocityCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receivables by age',
                                    style: tokens.bricolage(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppSpacing.vS,
                                  VelocityHorizontalBars(
                                    items: [
                                      VelocityHorizontalBarItem(
                                        label: 'Not due yet',
                                        value: ageBins[0],
                                        color: tokens.inColor,
                                      ),
                                      VelocityHorizontalBarItem(
                                        label: '1–30 days late',
                                        value: ageBins[1],
                                        color: tokens.owedColor,
                                      ),
                                      VelocityHorizontalBarItem(
                                        label: '31–60 days late',
                                        value: ageBins[2],
                                        color: tokens.outColor,
                                      ),
                                      VelocityHorizontalBarItem(
                                        label: '60+ days late',
                                        value: ageBins[3],
                                        color: tokens.outColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!isWide) ...[
                      AppSpacing.vS,
                      VelocityCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receivables by age',
                              style: tokens.bricolage(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppSpacing.vS,
                            VelocityHorizontalBars(
                              items: [
                                VelocityHorizontalBarItem(
                                  label: 'Not due yet',
                                  value: ageBins[0],
                                  color: tokens.inColor,
                                ),
                                VelocityHorizontalBarItem(
                                  label: '1–30 days late',
                                  value: ageBins[1],
                                  color: tokens.owedColor,
                                ),
                                VelocityHorizontalBarItem(
                                  label: '31–60 days late',
                                  value: ageBins[2],
                                  color: tokens.outColor,
                                ),
                                VelocityHorizontalBarItem(
                                  label: '60+ days late',
                                  value: ageBins[3],
                                  color: tokens.outColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            AppSpacing.vXL,

            // Coming up Section
            Text(
              'Coming up',
              style: tokens.bricolage(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.vS,
            if (soon.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Text(
                  'Nothing due. Add due dates to debts and receivables to see them here.',
                  style: tokens.figtree(
                    fontSize: 14,
                    color: tokens.muteColor,
                  ),
                ),
              )
            else
              for (final item in soon) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.lineColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: tokens.figtree(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.inkColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.isOverdue) ...[
                                  AppSpacing.hXS,
                                  const VelocityTag(
                                    label: 'overdue',
                                    variant: VelocityTagVariant.late,
                                  ),
                                ],
                              ],
                            ),
                            AppSpacing.vXXS,
                            Text(
                              item.dueDate.toIso8601String().substring(0, 10),
                              style: tokens.figtree(
                                fontSize: 14,
                                color: tokens.muteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hS,
                      Text(
                        FinancialNumberFormatter.format(item.amount),
                        style: tokens.bricolage(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: item.isPay ? tokens.outColor : tokens.inColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
    );
  }
}

class _UpcomingItem {
  final String title;
  final DateTime dueDate;
  final double amount;
  final bool isPay;
  final bool isOverdue;

  _UpcomingItem({
    required this.title,
    required this.dueDate,
    required this.amount,
    required this.isPay,
    required this.isOverdue,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
        ),
        Text(
          value,
          style: tokens.figtree(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tokens.inkColor,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.lineColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tokens.figtree(
              fontSize: 14,
              color: tokens.muteColor,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: tokens.bricolage(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
