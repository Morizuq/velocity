import 'package:flutter/material.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_font_weight.dart';
import '../tokens/app_icon_size.dart';
import '../tokens/app_spacing.dart';
import '../tokens/brand_colors.dart';

/// Reusable, interactive empty state card with borderless luxury styling.
class VelocityEmptyStateCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final String? badgeLabel;
  final Color? badgeColor;

  const VelocityEmptyStateCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.badgeLabel,
    this.badgeColor,
  });

  @override
  State<VelocityEmptyStateCard> createState() => _VelocityEmptyStateCardState();
}

class _VelocityEmptyStateCardState extends State<VelocityEmptyStateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBadgeColor = widget.badgeColor ?? widget.iconColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: brandColors.surfaceCard,
          borderRadius: AppBorderRadius.allXL,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.18)
                  : const Color(0x06000000),
              blurRadius: _isHovered ? 24 : 14,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating glowing icon circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(
                  alpha: _isHovered ? 0.18 : 0.10,
                ),
                shape: BoxShape.circle,
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: AppIconSize.m,
                color: widget.iconColor,
              ),
            ),
            AppSpacing.vM,
            if (widget.badgeLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s + 2,
                  vertical: AppSpacing.xxs + 1,
                ),
                decoration: BoxDecoration(
                  color: resolvedBadgeColor.withValues(alpha: 0.12),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Text(
                  widget.badgeLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: resolvedBadgeColor,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              AppSpacing.vS,
            ],
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: AppFontWeight.bold,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vXS,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                widget.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.75,
                  ),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.vL,
            ElevatedButton.icon(
              onPressed: widget.onAction,
              icon: const Icon(Icons.add_rounded, size: AppIconSize.s),
              label: Text(widget.actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.iconColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m - 2,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.pill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
