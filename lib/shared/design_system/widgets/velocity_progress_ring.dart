import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';

/// Circular progress ring matching Velocity Redesign:
/// CustomPainter with round stroke caps, track in `--line`, value in semantic color,
/// and percentage displayed in the center using Bricolage Grotesque.
class VelocityProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (or higher clamped)
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool showPercentage;

  const VelocityProgressRing({
    super.key,
    required this.progress,
    this.color,
    this.size = 64,
    this.strokeWidth = 7,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ringColor = color ?? tokens.accent;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return Semantics(
      label: '$pct percent complete',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: tokens.line,
                progressColor: ringColor,
                strokeWidth: strokeWidth,
              ),
            ),
            if (showPercentage)
              Text(
                '$pct%',
                style: tokens.bricolage(
                  fontSize: size >= 80 ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc with round stroke cap
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
