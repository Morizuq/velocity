import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/velocity_tokens.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../clearance/domain/entities/debt_entity.dart';

/// 24-month debt balance burndown projection line chart
class VelocityPayoffChart extends StatelessWidget {
  final List<DebtEntity> debts;

  const VelocityPayoffChart({super.key, required this.debts});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Simulate 24 months
    final balances = debts
        .map((d) => _DebtSim(
              remaining: math.max(0.0, d.totalOwed - d.amountPaid),
              monthlyPayment: d.monthlyPayment,
            ))
        .toList();

    final List<double> points = [];
    for (int k = 0; k <= 24; k++) {
      final totalForMonth = balances.fold<double>(0.0, (s, x) => s + x.remaining);
      points.add(totalForMonth);
      for (final b in balances) {
        b.remaining = math.max(0.0, b.remaining - b.monthlyPayment);
      }
    }

    final maxDebt = points.isNotEmpty ? points.first : 0.0;
    if (maxDebt <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No debt to project.',
          style: tokens.figtree(
            fontSize: 14,
            color: tokens.muteColor,
          ),
        ),
      );
    }

    final clearedMonth = points.indexWhere((v) => v <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Max Debt label
        Text(
          FinancialNumberFormatter.format(maxDebt),
          style: tokens.figtree(
            fontSize: 12,
            color: tokens.muteColor,
          ),
        ),
        const SizedBox(height: 6),

        // Line Chart Area
        SizedBox(
          height: 100,
          child: CustomPaint(
            painter: _PayoffPainter(
              points: points,
              maxDebt: maxDebt,
              lineColor: tokens.lineColor,
              outColor: tokens.outColor,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // X-axis timeline markers: "Now", "12 mo", "24 mo"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Now',
              style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
            ),
            Text(
              '12 mo',
              style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
            ),
            Text(
              '24 mo',
              style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Summary statement
        Text(
          clearedMonth > 0
              ? 'Debt-free in about $clearedMonth months at current payments.'
              : 'Not cleared within 24 months at current payments.',
          style: tokens.figtree(
            fontSize: 13,
            color: tokens.muteColor,
          ),
        ),
      ],
    );
  }
}

class _DebtSim {
  double remaining;
  final double monthlyPayment;

  _DebtSim({required this.remaining, required this.monthlyPayment});
}

class _PayoffPainter extends CustomPainter {
  final List<double> points;
  final double maxDebt;
  final Color lineColor;
  final Color outColor;

  _PayoffPainter({
    required this.points,
    required this.maxDebt,
    required this.lineColor,
    required this.outColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw baseline
    final baselineY = size.height - 4;
    final baselinePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    // Draw Polyline
    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final ratio = maxDebt > 0 ? (points[i] / maxDebt).clamp(0.0, 1.0) : 0.0;
      final y = baselineY - (ratio * (size.height - 12));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = outColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PayoffPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxDebt != maxDebt ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.outColor != outColor;
  }
}
