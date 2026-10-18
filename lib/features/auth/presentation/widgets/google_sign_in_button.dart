import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../controllers/auth_controller.dart';

/// Premium, high-converting Google Sign-In button built for Velocity Web.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final bool isCompact;

  const GoogleSignInButton({super.key, this.onSuccess, this.isCompact = false});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isHovered = false;

  Future<void> _handleSignIn() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();

    if (!mounted) return;

    if (success) {
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully signed in with Google'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        final errStr = authState.error.toString();
        // Don't show scary error if user simply closed the popup
        if (!errStr.contains('popup-closed-by-user')) {
          final String displayMessage;
          if (errStr.contains('unauthorized-domain')) {
            displayMessage =
                'This domain is not authorized in Firebase Console (Authentication > Settings > Authorized domains).';
          } else {
            displayMessage = 'Sign-in failed: ${authState.error}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    final background = isDark
        ? (_isHovered
              ? brandColors.mid.withValues(alpha: 0.3)
              : brandColors.surfaceCard)
        : (_isHovered ? const Color(0xFFF1F5F9) : Colors.white);

    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.wait : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppBorderRadius.pill,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.2)
                  : const Color(0x0A000000),
              blurRadius: _isHovered ? 14 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : _handleSignIn,
            borderRadius: AppBorderRadius.pill,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? AppSpacing.s + 3 : AppSpacing.l,
                vertical: widget.isCompact
                    ? AppSpacing.xs + 2
                    : AppSpacing.m - 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: AppIconSize.s,
                      height: AppIconSize.s,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          brandColors.accent,
                        ),
                      ),
                    ),
                    if (!widget.isCompact) ...[
                      AppSpacing.hS,
                      Text(
                        'Signing in...',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: AppFontWeight.semiBold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ] else ...[
                    const _GoogleIcon(size: 18),
                    AppSpacing.hS,
                    Text(
                      widget.isCompact ? 'Sign In' : 'Continue with Google',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        letterSpacing: 0.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom vector drawing of official Google 4-color 'G' mark.
class _GoogleIcon extends StatelessWidget {
  final double size;

  const _GoogleIcon({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Official Google Brand Colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final double scale = size.width / 24.0;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Blue path (crossbar and right arc)
    final bluePath = Path()
      ..moveTo(23.49 * scale, 12.27 * scale)
      ..cubicTo(
        23.49 * scale,
        11.47 * scale,
        23.42 * scale,
        10.72 * scale,
        23.3 * scale,
        10.0 * scale,
      )
      ..lineTo(12.0 * scale, 10.0 * scale)
      ..lineTo(12.0 * scale, 14.65 * scale)
      ..lineTo(18.45 * scale, 14.65 * scale)
      ..cubicTo(
        18.17 * scale,
        16.14 * scale,
        17.33 * scale,
        17.41 * scale,
        16.07 * scale,
        18.26 * scale,
      )
      ..lineTo(16.07 * scale, 21.31 * scale)
      ..lineTo(19.92 * scale, 21.31 * scale)
      ..cubicTo(
        22.17 * scale,
        19.23 * scale,
        23.49 * scale,
        16.03 * scale,
        23.49 * scale,
        12.27 * scale,
      )
      ..close();
    paint.color = blue;
    canvas.drawPath(bluePath, paint);

    // 2. Green path (bottom arc)
    final greenPath = Path()
      ..moveTo(12.0 * scale, 24.0 * scale)
      ..cubicTo(
        15.24 * scale,
        24.0 * scale,
        17.96 * scale,
        22.92 * scale,
        19.92 * scale,
        21.31 * scale,
      )
      ..lineTo(16.07 * scale, 18.26 * scale)
      ..cubicTo(
        15.0 * scale,
        18.98 * scale,
        13.62 * scale,
        19.41 * scale,
        12.0 * scale,
        19.41 * scale,
      )
      ..cubicTo(
        8.87 * scale,
        19.41 * scale,
        6.22 * scale,
        17.29 * scale,
        5.27 * scale,
        14.43 * scale,
      )
      ..lineTo(1.39 * scale, 14.43 * scale)
      ..lineTo(1.39 * scale, 17.44 * scale)
      ..cubicTo(
        3.34 * scale,
        21.32 * scale,
        7.36 * scale,
        24.0 * scale,
        12.0 * scale,
        24.0 * scale,
      )
      ..close();
    paint.color = green;
    canvas.drawPath(greenPath, paint);

    // 3. Yellow path (left arc)
    final yellowPath = Path()
      ..moveTo(5.27 * scale, 14.43 * scale)
      ..cubicTo(
        5.03 * scale,
        13.7 * scale,
        4.9 * scale,
        12.92 * scale,
        4.9 * scale,
        12.0 * scale,
      )
      ..cubicTo(
        4.9 * scale,
        11.08 * scale,
        5.03 * scale,
        10.3 * scale,
        5.27 * scale,
        9.57 * scale,
      )
      ..lineTo(5.27 * scale, 6.56 * scale)
      ..lineTo(1.39 * scale, 6.56 * scale)
      ..cubicTo(
        0.57 * scale,
        8.2 * scale,
        0.1 * scale,
        10.05 * scale,
        0.1 * scale,
        12.0 * scale,
      )
      ..cubicTo(
        0.1 * scale,
        13.95 * scale,
        0.57 * scale,
        15.8 * scale,
        1.39 * scale,
        17.44 * scale,
      )
      ..lineTo(5.27 * scale, 14.43 * scale)
      ..close();
    paint.color = yellow;
    canvas.drawPath(yellowPath, paint);

    // 4. Red path (top arc)
    final redPath = Path()
      ..moveTo(12.0 * scale, 4.59 * scale)
      ..cubicTo(
        13.76 * scale,
        4.59 * scale,
        15.34 * scale,
        5.2 * scale,
        16.59 * scale,
        6.39 * scale,
      )
      ..lineTo(20.0 * scale, 2.98 * scale)
      ..cubicTo(
        17.95 * scale,
        1.07 * scale,
        15.23 * scale,
        0.0 * scale,
        12.0 * scale,
        0.0 * scale,
      )
      ..cubicTo(
        7.36 * scale,
        0.0 * scale,
        3.34 * scale,
        2.68 * scale,
        1.39 * scale,
        6.56 * scale,
      )
      ..lineTo(5.27 * scale, 9.57 * scale)
      ..cubicTo(
        6.22 * scale,
        6.71 * scale,
        8.87 * scale,
        4.59 * scale,
        12.0 * scale,
        4.59 * scale,
      )
      ..close();
    paint.color = red;
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
