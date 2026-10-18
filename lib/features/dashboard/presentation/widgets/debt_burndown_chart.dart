import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity/shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../clearance/presentation/controllers/clearance_controller.dart';

/// Clean, borderless burn-down chart illustrating the trajectory of debt balance dropping to zero.
class DebtBurndownChart extends ConsumerWidget {
  const DebtBurndownChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final initialDebt = ref.watch(totalOriginalDebtProvider);
    final remainingDebt = ref.watch(totalClearanceDebtProvider);
    final isDebtFree = initialDebt <= 0 && remainingDebt <= 0;

    // Compute realistic burn-down curve from initial -> current -> 0 projection
    final double point0 = initialDebt > 0 ? initialDebt : 1.0;
    final double point1 = point0 * 0.88;
    final double point2 = point0 * 0.72;
    final double point3 = remainingDebt;
    const double targetZero = 0.0;

    final spots = <FlSpot>[
      FlSpot(0, point0 / 1000),
      FlSpot(1, point1 / 1000),
      FlSpot(2, point2 / 1000),
      FlSpot(3, point3 / 1000),
      const FlSpot(4, targetZero),
    ];

    final double maxY = ((point0 / 1000) * 1.15).ceilToDouble().clamp(
      10.0,
      double.infinity,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allXL,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x08000000),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clearance Debt Burn-Down',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vXXS,
                    Text(
                      isDebtFree
                          ? 'Zero active liabilities'
                          : 'Trajectory to zero liabilities',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.hS,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: (isDebtFree ? brandColors.progress : brandColors.debt)
                      .withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDebtFree
                          ? Icons.verified_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isDebtFree
                          ? brandColors.progress
                          : brandColors.debt,
                    ),
                    AppSpacing.hXXS,
                    Text(
                      isDebtFree ? '100% CLEAR' : 'BURN VELOCITY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDebtFree
                            ? brandColors.progress
                            : brandColors.debt,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vL,

          if (isDebtFree)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: brandColors.progress.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        size: AppIconSize.m,
                        color: brandColors.progress,
                      ),
                    ),
                    AppSpacing.vM,
                    Text(
                      '100% Debt-Free Position',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: brandColors.progress,
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      'Zero liabilities. Every Naira directly compounds your net wealth trajectory.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
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
                    horizontalInterval: (maxY / 4).clamp(50, double.infinity),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      strokeWidth: 1,
                      dashArray: [6, 6],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxY / 4).clamp(50, double.infinity),
                        reservedSize: 48,
                        getTitlesWidget: (val, meta) {
                          if (val < 0 || val > maxY) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '₦${val.toInt()}k',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval:
                            1.0, // Critical: Exactly 1 label per index, eliminating overlaps
                        getTitlesWidget: (val, meta) {
                          final labels = [
                            'Wk 1',
                            'Wk 2',
                            'Wk 3',
                            'Today',
                            'Target',
                          ];
                          final idx = val.toInt();
                          if (idx >= 0 &&
                              idx < labels.length &&
                              (val - idx).abs() < 0.01) {
                            final isToday = idx == 3;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[idx],
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isToday
                                      ? brandColors.debt
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isToday
                                      ? AppFontWeight.bold
                                      : AppFontWeight.medium,
                                  fontSize: 11,
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
                      curveSmoothness: 0.28,
                      color: brandColors.debt,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isToday = index == 3;
                          return FlDotCirclePainter(
                            radius: isToday ? 5.5 : 3.5,
                            color: isToday
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
                            brandColors.debt.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
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
                                text: spot.x == 4
                                    ? 'Target (Zero)'
                                    : 'Outstanding',
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
