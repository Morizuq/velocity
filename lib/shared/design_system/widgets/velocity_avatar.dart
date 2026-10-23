import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';

import '../tokens/app_border_radius.dart';

/// Entity Avatar matching Velocity Redesign:
/// 40x40px, 12px border radius ([AppBorderRadius.allAvatar]), initial letter in Bricolage Grotesque (700, 18px),
/// colored with semantic tint and soft background.
class VelocityAvatar extends StatelessWidget {
  final String? label;
  final String? name;
  final Color color;
  final double size;

  const VelocityAvatar({
    super.key,
    this.label,
    this.name,
    required this.color,
    this.size = 40,
  }) : assert(label != null || name != null, 'Either label or name must be provided');

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = (label ?? name ?? '').trim();
    final initial = text.isNotEmpty
        ? text.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppBorderRadius.allAvatar,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: tokens.bricolage(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
