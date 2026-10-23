import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../tokens/app_spacing.dart';

/// Standard page wrapper enforcing the Velocity design guidelines:
/// - Page max-width: 880px
/// - 16px horizontal side padding ([AppSpacing.m])
/// - 20px top padding
/// - 96px bottom content padding ([AppSpacing.bottomClearance]) to clear the fixed bottom navigation bar
/// - Safe area insets respected
class VelocityScaffold extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  final bool scrollable;

  const VelocityScaffold({
    super.key,
    required this.child,
    this.scrollController,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          20,
          AppSpacing.m,
          AppSpacing.bottomClearance,
        ),
        child: child,
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Align(
          alignment: Alignment.topCenter,
          child: content,
        ),
      );
    } else {
      content = Align(
        alignment: Alignment.topCenter,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }
}
