import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/velocity_tokens.dart';

class VelocityDonutSlice {
  final String label;
  final double amount;
  final Color color;

  const VelocityDonutSlice({
    required this.label,
    required this.amount,
    required this.color,
  });
}

/// Custom Donut Chart and legend list widget for recurring expenses breakdown
class VelocityDonutChart extends StatelessWidget {
  final List<VelocityDonutSlice> slices;
  final double size;

  const VelocityDonutChart({
    super.key,
    required this.slices,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final total = slices.fold<double>(0.0, (sum, s) => sum + s.amount);

    if (total <= 0 || slices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Add recurring expenses to see the breakdown.',
          style: tokens.figtree(
            fontSize: 14,
            color: tokens.muteColor,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 280;

        final chartWidget = SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(
              slices: slices,
              total: total,
            ),
          ),
        );

        final legendWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final slice in slices) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          slice.label,
                          style: tokens.figtree(
                            fontSize: 14,
                            color: tokens.inkColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(slice.amount / total * 100).round()}%',
                      style: tokens.bricolage(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.inkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

        if (isNarrow) {
          return Column(
            children: [
              Center(child: chartWidget),
              const SizedBox(height: 12),
              legendWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chartWidget,
            const SizedBox(width: 20),
            Expanded(child: legendWidget),
          ],
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<VelocityDonutSlice> slices;
  final double total;

  _DonutPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 16.0;

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.slices != slices;
  }
}
