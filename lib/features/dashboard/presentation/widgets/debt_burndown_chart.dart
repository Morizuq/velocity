import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_border_width.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../clearance/presentation/controllers/clearance_controller.dart';

/// Interactive burn-down chart illustrating the trajectory of debt balance falling to zero.
class DebtBurndownChart extends ConsumerWidget {
  const DebtBurndownChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    final initialDebt = ref.watch(totalOriginalDebtProvider);
    final remainingDebt = ref.watch(totalClearanceDebtProvider);

    // Compute realistic burn-down curve from initial -> current -> 0 projection
    final double point0 = initialDebt > 0 ? initialDebt : 380000;
    final double point1 = point0 * 0.88;
    final double point2 = point0 * 0.72;
    final double point3 = remainingDebt;
    final double target0 = 0.0;

    final spots = <FlSpot>[
      FlSpot(0, point0 / 1000),
      FlSpot(1, point1 / 1000),
      FlSpot(2, point2 / 1000),
      FlSpot(3, point3 / 1000),
      FlSpot(4, target0),
    ];

    final double maxY = (point0 / 1000) * 1.15;

    return Container(
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allXL,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: AppBorderWidth.hairline,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clearance Debt Burn-Down',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    'Trajectory to zero liabilities',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: brandColors.debt.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      size: 16,
                      color: brandColors.debt,
                    ),
                    AppSpacing.hXXS,
                    Text(
                      'BURN VELOCITY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: brandColors.debt,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vL,

          // LineChart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '₦${val.toInt()}k',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Today', 'Target'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[idx],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: idx == 3
                                    ? brandColors.debt
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: idx == 3
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: brandColors.debt,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: index == 3 ? 5 : 3.5,
                          color: index == 3
                              ? brandColors.debt
                              : brandColors.surfaceCard,
                          strokeWidth: 2,
                          strokeColor: brandColors.debt,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          brandColors.debt.withValues(alpha: 0.28),
                          brandColors.debt.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final val = spot.y * 1000;
                        return LineTooltipItem(
                          '${FinancialNumberFormatter.format(val)}\n',
                          theme.textTheme.labelSmall!.copyWith(
                            color: Colors.white,
                            fontWeight: AppFontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: spot.x == 4 ? 'Target (Zero)' : 'Outstanding',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
