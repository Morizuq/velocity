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
import '../../../milestones/presentation/controllers/milestones_controller.dart';

/// Donut chart visualizing Total Liquid Cash vs Total Debt vs Goal Progress.
class FinancialVelocityDonutChart extends ConsumerStatefulWidget {
  final double totalLiquidCash;

  const FinancialVelocityDonutChart({
    super.key,
    required this.totalLiquidCash,
  });

  @override
  ConsumerState<FinancialVelocityDonutChart> createState() =>
      _FinancialVelocityDonutChartState();
}

class _FinancialVelocityDonutChartState
    extends ConsumerState<FinancialVelocityDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    final totalDebt = ref.watch(totalClearanceDebtProvider);
    final totalMilestoneSaved = ref.watch(totalMilestoneSavedProvider);

    final double cashVal = widget.totalLiquidCash > 0 ? widget.totalLiquidCash : 1.0;
    final double debtVal = totalDebt > 0 ? totalDebt : 0.0;
    final double goalsVal = totalMilestoneSaved > 0 ? totalMilestoneSaved : 0.0;

    final double totalAggregate = cashVal + debtVal + goalsVal;

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        color: brandColors.progress,
        value: cashVal,
        title: '',
        radius: _touchedIndex == 0 ? 30.0 : 24.0,
      ),
      PieChartSectionData(
        color: brandColors.debt,
        value: debtVal,
        title: '',
        radius: _touchedIndex == 1 ? 30.0 : 24.0,
      ),
      PieChartSectionData(
        color: brandColors.milestone,
        value: goalsVal,
        title: '',
        radius: _touchedIndex == 2 ? 30.0 : 24.0,
      ),
    ];

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
              Text(
                'Financial Velocity Matrix',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: brandColors.subtle,
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Text(
                  'Macro Breakdown',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: brandColors.mid,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vL,

          // Donut Chart with Center Net Position
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    sections: sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LIQUID RATIO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      totalAggregate > 0
                          ? '${((cashVal / totalAggregate) * 100).round()}%'
                          : '100%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vL,

          // Legend
          _LegendItem(
            color: brandColors.progress,
            label: 'Liquid Cash',
            amount: FinancialNumberFormatter.format(widget.totalLiquidCash),
          ),
          AppSpacing.vS,
          _LegendItem(
            color: brandColors.debt,
            label: 'Active Clearance Dues',
            amount: FinancialNumberFormatter.format(totalDebt),
          ),
          AppSpacing.vS,
          _LegendItem(
            color: brandColors.milestone,
            label: 'Milestones Capital',
            amount: FinancialNumberFormatter.format(totalMilestoneSaved),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hS,
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }
}
