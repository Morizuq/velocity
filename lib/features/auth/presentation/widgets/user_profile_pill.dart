import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../controllers/auth_controller.dart';
import 'google_sign_in_button.dart';

/// Top bar user profile chip indicating live Google authentication state.
class UserProfilePill extends ConsumerWidget {
  final bool? isCompact;

  const UserProfilePill({super.key, this.isCompact});

  void _showUserSessionModal(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: brandColors.surfaceCard,
              borderRadius: AppBorderRadius.allXL,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : const Color(0x14000000),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: brandColors.accent.withValues(alpha: 0.2),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.initials,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                            color: brandColors.accent,
                          ),
                        )
                      : null,
                ),
                AppSpacing.vL,
                Text(
                  user.displayName ?? 'Google User',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null) ...[
                  AppSpacing.vXS,
                  Text(
                    user.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                AppSpacing.vM,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: brandColors.progress.withValues(alpha: 0.12),
                    borderRadius: AppBorderRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: brandColors.progress,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.hS,
                      Text(
                        'Google Authenticated (Web)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: brandColors.progress,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vXL,
                // Sign out button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully signed out'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2A1B1E)
                          : const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.pill,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: AppIconSize.s,
                          color: Color(0xFFEF4444),
                        ),
                        AppSpacing.hS,
                        Text(
                          'Sign Out of Google',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    final effectiveCompact =
        isCompact ?? (MediaQuery.sizeOf(context).width < 560);

    if (user == null) {
      return const GoogleSignInButton(isCompact: true);
    }

    return Tooltip(
      message: 'Account: ${user.displayLabel}',
      child: InkWell(
        onTap: () => _showUserSessionModal(context, ref, user),
        borderRadius: AppBorderRadius.pill,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: effectiveCompact ? AppSpacing.xs + 2 : AppSpacing.s + 2,
            vertical: AppSpacing.xs + 1,
          ),
          decoration: BoxDecoration(
            color: brandColors.surfaceCard,
            borderRadius: AppBorderRadius.pill,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0x06000000),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: brandColors.accent.withValues(alpha: 0.2),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.initials,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: brandColors.accent,
                          fontSize: 10,
                        ),
                      )
                    : null,
              ),
              if (!effectiveCompact) ...[
                AppSpacing.hS,
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    user.displayLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              AppSpacing.hXXS,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppIconSize.s - 4,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
