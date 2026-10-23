import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/widgets/velocity_data_export_import.dart';

/// Clean circular header action button for opening the Data Backup & Transfer sheet.
/// Uses a borderless container with circular geometry to seamlessly match the
/// 32px height and styling of adjacent navigation controls (ThemeModeToggle and UserProfilePill).
/// Employs a font-independent vector painter so the sync icon renders 100% reliably
/// in all environments (development, production, tree-shaken builds, and offline).
class HeaderDataSyncButton extends StatefulWidget {
  const HeaderDataSyncButton({super.key});

  @override
  State<HeaderDataSyncButton> createState() => _HeaderDataSyncButtonState();
}

class _HeaderDataSyncButtonState extends State<HeaderDataSyncButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brandColors = context.brandColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonize background tone with adjacent ThemeModeToggle and UserProfilePill
    final bgColor = isDark
        ? (_isHovered ? const Color(0xFF1A2333) : const Color(0xFF131A26))
        : (_isHovered ? const Color(0xFFEDF2F7) : const Color(0xFFE2E8F0));

    final iconColor = _isHovered ? tokens.ink : tokens.muteColor;

    return Tooltip(
      message: 'Backup & Transfer Data',
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.15)
                    : const Color(0x0A000000),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 2 : 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => VelocityDataExportImportSheet.show(context),
              splashColor: brandColors.accent.withValues(alpha: 0.15),
              highlightColor: brandColors.accent.withValues(alpha: 0.08),
              child: Center(
                child: _VelocitySyncIcon(color: iconColor, size: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Font-independent resolution-proof vector sync icon.
/// Eliminates all dependency on Web font asset bundling and icon tree shaking.
class _VelocitySyncIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _VelocitySyncIcon({required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SyncIconPainter(color: color),
      ),
    );
  }
}

class _SyncIconPainter extends CustomPainter {
  final Color color;

  const _SyncIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arc 1 (Top right clockwise to bottom)
    const sweep = math.pi * 0.72;
    const start1 = -math.pi * 0.18;
    canvas.drawArc(rect, start1, sweep, false, stroke);

    // Arrowhead 1
    final end1 = start1 + sweep;
    final tip1 = Offset(
      center.dx + radius * math.cos(end1),
      center.dy + radius * math.sin(end1),
    );
    final p1 = Path()
      ..moveTo(tip1.dx, tip1.dy)
      ..lineTo(tip1.dx - 3.5, tip1.dy - 1.2)
      ..lineTo(tip1.dx - 1.2, tip1.dy - 3.8)
      ..close();
    canvas.drawPath(p1, fill);

    // Arc 2 (Bottom left clockwise to top)
    const start2 = math.pi * 0.82;
    canvas.drawArc(rect, start2, sweep, false, stroke);

    // Arrowhead 2
    final end2 = start2 + sweep;
    final tip2 = Offset(
      center.dx + radius * math.cos(end2),
      center.dy + radius * math.sin(end2),
    );
    final p2 = Path()
      ..moveTo(tip2.dx, tip2.dy)
      ..lineTo(tip2.dx + 3.5, tip2.dy + 1.2)
      ..lineTo(tip2.dx + 1.2, tip2.dy + 3.8)
      ..close();
    canvas.drawPath(p2, fill);
  }

  @override
  bool shouldRepaint(covariant _SyncIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
