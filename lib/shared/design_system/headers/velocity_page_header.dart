import 'package:flutter/material.dart';
import '../tokens/app_font_weight.dart';
import '../tokens/app_responsive.dart';
import '../tokens/app_spacing.dart';

/// Standard responsive page header widget across the Velocity platform.
///
/// Automatically adapts its layout structure across screen breakpoints:
/// - **Mobile (< 600px)**: Stacks the title, description, and action buttons
///   vertically in a [Column], allowing actions to wrap naturally with full width.
/// - **Tablet / Desktop (>= 600px)**: Aligns the title/description block on the left
///   and actions on the right in a balanced horizontal [Row].
class VelocityPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const VelocityPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;

    final titleWidget = Text(
      title,
      style: titleStyle ??
          theme.textTheme.headlineMedium?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
    );

    final subtitleWidget = Text(
      subtitle,
      style: subtitleStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
    );

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleWidget,
        AppSpacing.vXXS,
        subtitleWidget,
      ],
    );

    if (actions == null || actions!.isEmpty) {
      return textColumn;
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          textColumn,
          AppSpacing.vM,
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: actions!,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: textColumn),
        AppSpacing.hM,
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions!,
        ),
      ],
    );
  }
}
