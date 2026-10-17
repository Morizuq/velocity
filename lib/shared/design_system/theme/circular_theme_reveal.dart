import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_notifier.dart';

/// Provides a fluid, organic water-bleed theme transition with concentric capillary
/// ripples and continuous mathematical [ThemeData.lerp] color diffusion.
///
/// Prevents global screen flashes by maintaining state stability during the fluid
/// animation and only committing persistent state upon wavefront completion.
class CircularThemeReveal extends ConsumerStatefulWidget {
  final Widget child;
  final Duration duration;

  const CircularThemeReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 620),
  });

  static CircularThemeRevealState? of(BuildContext context) {
    return context.findAncestorStateOfType<CircularThemeRevealState>();
  }

  @override
  ConsumerState<CircularThemeReveal> createState() =>
      CircularThemeRevealState();
}

class CircularThemeRevealState extends ConsumerState<CircularThemeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _isAnimating = false;
  Offset _focalPoint = Offset.zero;
  ThemeData _fromTheme = AppTheme.darkTheme;
  ThemeData _toTheme = AppTheme.lightTheme;
  bool _isGoingDark = false;

  bool get isAnimating => _isAnimating;
  bool get isTargetDark => _isGoingDark;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _animation.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers a fluid water-bleed transition originating from [focalPoint].
  /// - Going to Dark: Bleeds and expands OUTWARD like dark ink in water.
  /// - Going to Light: Bleeds and sweeps INWARD like light flooding from the horizon.
  void toggleTheme({Offset? focalPoint}) {
    if (_isAnimating) return;

    final mediaQuery = MediaQuery.of(context);
    final fallbackCenter = Offset(mediaQuery.size.width - 50, 45);
    _focalPoint = focalPoint ?? fallbackCenter;

    final currentMode = ref.read(themeModeProvider);
    final isCurrentlyDark = currentMode == ThemeMode.dark;

    _isGoingDark = !isCurrentlyDark;
    _fromTheme = isCurrentlyDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    _toTheme = isCurrentlyDark ? AppTheme.lightTheme : AppTheme.darkTheme;

    // Immediately toggle theme mode so state updates reliably and persistently
    ref.read(themeModeProvider.notifier).toggleTheme();

    setState(() {
      _isAnimating = true;
    });

    _controller.forward(from: 0.0);
  }

  double _calculateMaxRadius(Size size, Offset center) {
    final d1 = (center - Offset.zero).distance;
    final d2 = (center - Offset(size.width, 0)).distance;
    final d3 = (center - Offset(0, size.height)).distance;
    final d4 = (center - Offset(size.width, size.height)).distance;
    return math.max(math.max(d1, d2), math.max(d3, d4));
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeMode = ref.watch(themeModeProvider);
    final baseStaticTheme = activeThemeMode == ThemeMode.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    // During the fluid bleed, continuously lerp every single color, card surface,
    // and font style frame-by-frame with zero flash.
    final activeTheme = _isAnimating
        ? ThemeData.lerp(_fromTheme, _toTheme, _animation.value)
        : baseStaticTheme;

    return Theme(
      data: activeTheme,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          if (_isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FluidWaterBleedPainter(
                    focalPoint: _focalPoint,
                    progress: _animation.value,
                    maxRadius: _calculateMaxRadius(
                      MediaQuery.of(context).size,
                      _focalPoint,
                    ),
                    isGoingDark: _isGoingDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders authentic fluid surface-tension ripples, feathered diffusion boundaries,
/// and organic water bleed waves.
class _FluidWaterBleedPainter extends CustomPainter {
  final Offset focalPoint;
  final double progress;
  final double maxRadius;
  final bool isGoingDark;

  _FluidWaterBleedPainter({
    required this.focalPoint,
    required this.progress,
    required this.maxRadius,
    required this.isGoingDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Liquid velocity physics:
    // When going dark: fluid expands OUTWARD (0 -> maxRadius)
    // When going light: fluid converges INWARD (maxRadius -> 0)
    final currentRadius = isGoingDark
        ? progress * maxRadius
        : (1.0 - progress) * maxRadius;

    // Organic fluid pulse envelope: peaks mid-spread then gently settles
    final fluidIntensity = math.sin(progress * math.pi);

    if (isGoingDark) {
      // ========================================================
      // DARK THEME: NOCTURNAL INK BLEEDING OUTWARD FROM BUTTON
      // ========================================================
      const fluidCyan = Color(0xFF00D2FF);
      const deepIndigo = Color(0xFF0B101B);

      // 1. Feathered ink diffusion pool (deep saturation near origin, soft bleed at perimeter)
      final diffusionPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (focalPoint.dx / size.width) * 2 - 1,
            (focalPoint.dy / size.height) * 2 - 1,
          ),
          radius: (currentRadius / math.max(size.width, size.height)).clamp(
            0.01,
            2.5,
          ),
          colors: [
            deepIndigo.withValues(alpha: 0.35 * fluidIntensity),
            fluidCyan.withValues(alpha: 0.18 * fluidIntensity),
            fluidCyan.withValues(alpha: 0.08 * fluidIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 0.88, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawCircle(focalPoint, currentRadius, diffusionPaint);

      // 2. Primary luminous water wavefront (surface tension meniscus)
      final waveAlpha = (1.0 - progress * 0.75).clamp(0.0, 1.0);
      final primaryRingPaint = Paint()
        ..color = fluidCyan.withValues(alpha: 0.75 * waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

      canvas.drawCircle(focalPoint, currentRadius, primaryRingPaint);

      // Crisp inner meniscus refraction line
      final refractionPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(
        focalPoint,
        math.max(0, currentRadius - 2),
        refractionPaint,
      );

      // 3. Secondary harmonic trailing ripple (capillary wave)
      if (currentRadius > 35) {
        final rippleRadius = currentRadius * 0.84;
        final ripplePaint = Paint()
          ..color = fluidCyan.withValues(alpha: 0.35 * waveAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

        canvas.drawCircle(focalPoint, rippleRadius, ripplePaint);
      }

      // 4. Tertiary echo ripple for deep liquid realism
      if (currentRadius > 70) {
        final echoRadius = currentRadius * 0.68;
        final echoPaint = Paint()
          ..color = fluidCyan.withValues(alpha: 0.18 * waveAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawCircle(focalPoint, echoRadius, echoPaint);
      }
    } else {
      // ========================================================
      // LIGHT THEME: CELESTIAL WATER FLOODING INWARD TOWARD BUTTON
      // ========================================================
      const fluidSky = Color(0xFF0284C7);
      const sunlightCyan = Color(0xFF38BDF8);

      // 1. Daylight diffusion wash rolling INWARD from perimeter
      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: focalPoint, radius: currentRadius))
        ..fillType = PathFillType.evenOdd;

      final daylightWashPaint = Paint()
        ..color = sunlightCyan.withValues(alpha: 0.22 * fluidIntensity)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, daylightWashPaint);

      // 2. Primary converging water wavefront
      final waveAlpha = (0.40 + progress * 0.60).clamp(0.0, 1.0);
      final primaryRingPaint = Paint()
        ..color = fluidSky.withValues(alpha: 0.80 * waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawCircle(focalPoint, currentRadius, primaryRingPaint);

      // Refractive daylight meniscus line
      final refractionPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * waveAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(focalPoint, currentRadius + 2, refractionPaint);

      // 3. Trailing ripple outside the converging wavefront
      final outerRippleRadius = currentRadius * 1.12;
      if (outerRippleRadius < maxRadius) {
        final ripplePaint = Paint()
          ..color = sunlightCyan.withValues(alpha: 0.38 * waveAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(focalPoint, outerRippleRadius, ripplePaint);
      }

      // 4. Luminous fluid droplet burst when the wave converges onto the button
      if (currentRadius < 45) {
        final condensation = (1.0 - (currentRadius / 45)).clamp(0.0, 1.0);
        final dropletPaint = Paint()
          ..color = sunlightCyan.withValues(alpha: 0.65 * condensation)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

        canvas.drawCircle(focalPoint, 24.0 * condensation, dropletPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidWaterBleedPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.focalPoint != focalPoint ||
        oldDelegate.isGoingDark != isGoingDark;
  }
}
