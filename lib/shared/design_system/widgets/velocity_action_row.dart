import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../buttons/velocity_button.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

/// Reusable action bar for list cards across Velocity:
/// displays Priority rank, optional primary action button (e.g. Log payment),
/// Remove button, and reorder controls (Top, ↑, ↓, and drag handle).
class VelocityActionRow extends StatelessWidget {
  final int index;
  final int totalCount;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onEdit;
  final VoidCallback onRemove;
  final VoidCallback? onMoveTop;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Widget? dragHandle;

  const VelocityActionRow({
    super.key,
    required this.index,
    required this.totalCount,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onEdit,
    required this.onRemove,
    this.onMoveTop,
    this.onMoveUp,
    this.onMoveDown,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isFirst = index == 0;
    final isLast = index == totalCount - 1;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        // Left Actions: Priority Rank, Primary Action (Log payment / Add savings), Remove
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            Text(
              isFirst ? 'Top priority' : 'Priority ${index + 1}',
              style: tokens.figtree(
                fontSize: 13,
                fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                color: isFirst ? tokens.accentColor : tokens.muteColor,
              ),
            ),
            if (primaryActionLabel != null && onPrimaryAction != null)
              VelocityButton.soft(
                onPressed: onPrimaryAction,
                label: primaryActionLabel!,
                height: 28.0,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            if (onEdit != null)
              VelocityButton.subtle(
                onPressed: onEdit,
                label: 'Edit',
                height: 28.0,
              ),
            VelocityButton.subtle(
              onPressed: onRemove,
              label: 'Remove',
              height: 28.0,
            ),
          ],
        ),

        // Right Actions: Reorder Move Buttons (Top, ↑, ↓, Drag Grip)
        if (totalCount > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoveButton(
                label: 'Top',
                onTap: isFirst ? null : onMoveTop,
                tooltip: 'Move to top',
              ),
              AppSpacing.hXXS,
              _MoveButton(
                label: '↑',
                onTap: isFirst ? null : onMoveUp,
                tooltip: 'Move up',
              ),
              AppSpacing.hXXS,
              _MoveButton(
                label: '↓',
                onTap: isLast ? null : onMoveDown,
                tooltip: 'Move down',
              ),
              if (dragHandle != null) ...[AppSpacing.hXXS, dragHandle!],
            ],
          ),
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String tooltip;

  const _MoveButton({
    required this.label,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.allButton,
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.bgColor,
            border: Border.all(color: tokens.lineColor),
            borderRadius: AppBorderRadius.allButton,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.35,
            child: Text(
              label,
              style: tokens.figtree(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.muteColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
