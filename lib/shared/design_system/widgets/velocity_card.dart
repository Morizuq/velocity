import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

/// Card container matching Velocity Redesign:
/// 16px border radius ([AppBorderRadius.allCard]), 1px border in `--line`,
/// `--surface` background, zero elevation.
class VelocityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const VelocityCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.m),
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.surface,
        borderRadius: AppBorderRadius.allCard,
        border: Border.all(color: tokens.line, width: 1),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.allCard,
        child: card,
      );
    }

    return card;
  }
}

/// Hero card container matching Velocity Redesign:
/// 20px border radius ([AppBorderRadius.allHero]), 1px border in `--line`,
/// `--surface` background, 24px padding ([AppSpacing.l]).
class VelocityHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const VelocityHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: AppBorderRadius.allHero,
        border: Border.all(color: tokens.line, width: 1),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Note / Summary box container using `--soft` background with 12px radius.
class VelocityNoteBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const VelocityNoteBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.soft,
        borderRadius: AppBorderRadius.allAvatar,
      ),
      padding: padding,
      child: child,
    );
  }
}
