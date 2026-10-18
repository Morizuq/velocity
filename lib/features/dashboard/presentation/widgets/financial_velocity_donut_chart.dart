import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../clearance/presentation/controllers/clearance_controller.dart';
import '../../../milestones/presentation/controllers/milestones_controller.dart';

/// Clean, borderless Donut chart visualizing Total Liquid Cash vs Total Debt vs Goal Progress.
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
    final isDark = theme.brightness == Brightness.dark;

    final totalDebt = ref.watch(totalClearanceDebtProvider);
    final totalMilestoneSaved = ref.watch(totalMilestoneSavedProvider);

    final bool isEmpty = widget.totalLiquidCash <= 0 &&
        totalDebt <= 0 &&
        totalMilestoneSaved <= 0;

    final double cashVal = widget.totalLiquidCash;
    final double debtVal = totalDebt;
    final double goalsVal = totalMilestoneSaved;
    final double totalAggregate = cashVal + debtVal + goalsVal;

    final sections = isEmpty
        ? <PieChartSectionData>[
            PieChartSectionData(
              color: theme.colorScheme.surfaceContainerHigh,
              value: 1.0,
              title: '',
              radius: 18.0,
            ),
          ]
        : <PieChartSectionData>[
            if (cashVal > 0)
              PieChartSectionData(
                color: brandColors.progress,
                value: cashVal,
                title: '',
                radius: _touchedIndex == 0 ? 28.0 : 22.0,
              ),
            if (debtVal > 0)
              PieChartSectionData(
                color: brandColors.debt,
                value: debtVal,
                title: '',
                radius: _touchedIndex == 1 ? 28.0 : 22.0,
              ),
            if (goalsVal > 0)
              PieChartSectionData(
                color: brandColors.milestone,
                value: goalsVal,
                title: '',
                radius: _touchedIndex == 2 ? 28.0 : 22.0,
              ),
          ];

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
            children: [
              Expanded(
                child: Text(
                  'Financial Velocity Matrix',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hS,
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
                    color: brandColors.accent,
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
                      isEmpty ? 'ALLOCATION' : 'LIQUID RATIO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      isEmpty
                          ? '0%'
                          : (totalAggregate > 0
                              ? '${((cashVal / totalAggregate) * 100).round()}%'
                              : '0%'),
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
            label: 'Clearance Dues',
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
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              AppSpacing.hS,
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hS,
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }
}
