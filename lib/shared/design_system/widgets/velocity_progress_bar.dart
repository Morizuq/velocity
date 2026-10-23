import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../tokens/app_border_radius.dart';

/// Progress bar matching Velocity redesign:
/// 6px tall, 3px radius ([AppBorderRadius.allBar]), `--line` track, fill color in `--accent` or semantic color.
class VelocityProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final double height;

  const VelocityProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: height == 6.0 ? AppBorderRadius.allBar : BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: tokens.line,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              color: color ?? tokens.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Split bar segment definition.
class SplitBarSegment {
  final double value;
  final Color color;
  final String? label;

  const SplitBarSegment({
    required this.value,
    required this.color,
    this.label,
  });
}

typedef VelocitySplitSegment = SplitBarSegment;

/// Horizontal split bar showing relative distribution of budget / expenses / free cash.
/// 14px height, 7px radius ([AppBorderRadius.allSplitBar]), overflow hidden, track in `--line`.
class VelocitySplitBar extends StatelessWidget {
  final List<SplitBarSegment> segments;
  final double total;
  final double height;

  const VelocitySplitBar({
    super.key,
    required this.segments,
    required this.total,
    this.height = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final validTotal = total > 0 ? total : 1.0;

    return Semantics(
      label: 'Income distribution split bar',
      child: ClipRRect(
        borderRadius: height == 14.0 ? AppBorderRadius.allSplitBar : BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          color: tokens.line,
          child: Row(
            children: segments.map((seg) {
              if (seg.value <= 0) return const SizedBox.shrink();
              final flex = ((seg.value / validTotal) * 1000).round();
              if (flex <= 0) return const SizedBox.shrink();
              return Flexible(
                flex: flex,
                child: Container(
                  color: seg.color,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
