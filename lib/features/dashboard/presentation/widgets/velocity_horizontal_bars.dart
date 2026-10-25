import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/velocity_tokens.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';

class VelocityHorizontalBarItem {
  final String label;
  final double value;
  final Color color;

  const VelocityHorizontalBarItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Horizontal bar breakdown chart widget matching `.hb` in Velocity redesign
class VelocityHorizontalBars extends StatelessWidget {
  final List<VelocityHorizontalBarItem> items;
  final double? customMax;

  const VelocityHorizontalBars({
    super.key,
    required this.items,
    this.customMax,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final maxValue = customMax ??
        items.fold<double>(
          1.0,
          (maxSoFar, item) => math.max(maxSoFar, item.value),
        );

    return Column(
      children: [
        for (final item in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                // Label (fixed width for alignment)
                SizedBox(
                  width: 96,
                  child: Text(
                    item.label,
                    style: tokens.figtree(
                      fontSize: 14,
                      color: tokens.inkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacing.hXS,

                // Bar Track
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: tokens.lineColor,
                      borderRadius: AppBorderRadius.allPill,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fraction = maxValue > 0
                            ? (item.value / maxValue).clamp(0.0, 1.0)
                            : 0.0;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: constraints.maxWidth * fraction,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: AppBorderRadius.allPill,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                AppSpacing.hXS,

                // Amount (right aligned tabular display)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72),
                  child: Text(
                    FinancialNumberFormatter.format(item.value),
                    textAlign: TextAlign.right,
                    style: tokens.bricolage(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.inkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
