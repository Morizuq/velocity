import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/routes.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/velocity_icon.dart';
import 'controllers/auth_controller.dart';
import 'widgets/google_sign_in_button.dart';

/// Dedicated authentication and onboarding portal for Velocity Web.
class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authControllerProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: brandColors.surfaceCard,
                  borderRadius: AppBorderRadius.allXL,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : const Color(0x0C000000),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Identity
                    const VelocityIcon(height: 52),
                    AppSpacing.vL,
                    Text(
                      'VELOCITY',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    AppSpacing.vXS,
                    Text(
                      'Personal Wealth Trajectory Engine',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vXXL,

                    if (user != null) ...[
                      // Logged-in State Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: brandColors.accent.withValues(alpha: 0.08),
                          borderRadius: AppBorderRadius.allXL,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  brandColors.accent.withValues(alpha: 0.2),
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Text(
                                      user.initials,
                                      style: TextStyle(
                                        color: brandColors.accent,
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            AppSpacing.hM,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayLabel,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user.email != null)
                                    Text(
                                      user.email!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vL,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go(Routes.home),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.m,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.pill,
                            ),
                          ),
                          child: const Text('Open Wealth Dashboard'),
                        ),
                      ),
                      AppSpacing.vM,
                      TextButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                        child: Text(
                          'Sign Out',
                          style: TextStyle(color: brandColors.debt),
                        ),
                      ),
                    ] else ...[
                      // Unauthenticated state: Google Sign-In
                      const GoogleSignInButton(),
                      AppSpacing.vL,
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            child: Text(
                              'AUTHENTICATED VIA GOOGLE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                letterSpacing: 1.0,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vL,
                      _FeatureBullet(
                        icon: Icons.flash_on_rounded,
                        title: 'High-Velocity Analytics',
                        description:
                            'Real-time clearance debt burndown and capital tracking.',
                        iconColor: brandColors.accent,
                      ),
                      AppSpacing.vM,
                      _FeatureBullet(
                        icon: Icons.shield_rounded,
                        title: 'Private & Secure',
                        description:
                            'OAuth 2.0 Web authentication secured by Google Identity.',
                        iconColor: brandColors.progress,
                      ),
                      AppSpacing.vXL,
                      TextButton.icon(
                        onPressed: () => context.go(Routes.home),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: AppIconSize.s,
                        ),
                        label: const Text('Continue as Guest to Dashboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        AppSpacing.hM,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
