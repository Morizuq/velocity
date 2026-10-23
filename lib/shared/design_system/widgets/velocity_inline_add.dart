import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

/// Collapsible inline add section modeled after `<details class="addc"><summary>Add ...</summary>...`
class VelocityInlineAddSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const VelocityInlineAddSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<VelocityInlineAddSection> createState() =>
      _VelocityInlineAddSectionState();
}

class _VelocityInlineAddSectionState extends State<VelocityInlineAddSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Button (Collapsible Trigger)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: AppBorderRadius.allButton,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: tokens.softColor,
                borderRadius: AppBorderRadius.allButton,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: tokens.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.accentColor,
                    ),
                  ),
                  AppSpacing.hXS,
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: tokens.accentColor,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Form Content
          if (_isExpanded) ...[
            AppSpacing.vXS,
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: tokens.surfaceColor,
                border: Border.all(color: tokens.lineColor),
                borderRadius: AppBorderRadius.allCard,
              ),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
