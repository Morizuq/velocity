import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';

/// Premium sliding segmented theme mode toggle (Sun ☀️ vs Moon 🌙).
/// Replaces clunky text and artificial wave ripples with a native-feeling,
/// tactile macOS/iOS-style sliding switch that leverages smooth frame-by-frame
/// [ThemeData.lerp] color transitions.
class ThemeModeToggle extends ConsumerStatefulWidget {
  const ThemeModeToggle({super.key});

  @override
  ConsumerState<ThemeModeToggle> createState() => _ThemeModeToggleState();
}

class _ThemeModeToggleState extends ConsumerState<ThemeModeToggle> {
  bool _isHovered = false;

  void _handleToggle() {
    ref.read(themeModeProvider.notifier).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColors = context.brandColors;

    final trackBg = isDark
        ? (_isHovered ? const Color(0xFF172030) : const Color(0xFF131A26))
        : (_isHovered ? const Color(0xFFEDF2F7) : const Color(0xFFE2E8F0));

    final trackBorder = isDark
        ? (_isHovered
            ? brandColors.accent.withValues(alpha: 0.4)
            : const Color(0xFF222F46))
        : (_isHovered
            ? brandColors.accent.withValues(alpha: 0.4)
            : const Color(0xFFCBD5E1));

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          key: const Key('theme_mode_toggle'),
          onTap: _handleToggle,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: trackBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: trackBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0x08000000),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sliding indicator thumb
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: isDark
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : const Color(0x18000000),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Icon labels (Sun on left, Moon on right)
                Row(
                  children: [
                    // Sun icon slot
                    Expanded(
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: !isDark ? 1.0 : 0.35,
                          child: Icon(
                            Icons.wb_sunny_rounded,
                            size: 13,
                            color: !isDark
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),

                    // Moon icon slot
                    Expanded(
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isDark ? 1.0 : 0.35,
                          child: Icon(
                            Icons.nightlight_round,
                            size: 13,
                            color: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
