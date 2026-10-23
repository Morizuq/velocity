import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/widgets/velocity_data_export_import.dart';

/// Clean circular header action button for opening the Data Backup & Transfer sheet.
/// Uses a borderless container with circular geometry to seamlessly match the
/// 32px height and styling of adjacent navigation controls (ThemeModeToggle and UserProfilePill).
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
                child: Icon(Icons.sync, size: 16, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
