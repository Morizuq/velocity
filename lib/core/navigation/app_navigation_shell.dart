import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/widgets/user_profile_pill.dart';
import '../../features/dashboard/presentation/widgets/theme_mode_toggle.dart';
import '../../shared/design_system/tokens/app_border_radius.dart';
import '../../shared/design_system/tokens/app_font_weight.dart';
import '../../shared/design_system/tokens/app_responsive.dart';
import '../../shared/design_system/tokens/app_spacing.dart';
import '../../shared/design_system/tokens/brand_colors.dart';
import '../../shared/design_system/tokens/velocity_icon.dart';

/// Top-level responsive navigation shell hosting Dashboard, Clearance, Milestones, and Expenses.
class AppNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  void _onTapDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 960;
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive<double>(
                  mobile: AppSpacing.m,
                  tablet: AppSpacing.xl,
                  desktop: AppSpacing.xxl,
                ),
                vertical: AppSpacing.xs,
              ),
              child: LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompactScreen = headerConstraints.maxWidth < 600;
                  final showDesktopTabs = headerConstraints.maxWidth >= 960;
                  return Row(
                    children: [
                      // Logo Branding
                      InkWell(
                        onTap: () => _onTapDestination(0),
                        borderRadius: AppBorderRadius.allM,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VelocityIcon(height: 24),
                            AppSpacing.hXS,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'VELOCITY',
                                  style:
                                      (isCompactScreen
                                              ? theme.textTheme.titleSmall
                                              : theme.textTheme.titleMedium)
                                          ?.copyWith(
                                            fontWeight: AppFontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                ),
                                if (showDesktopTabs)
                                  Text(
                                    'Financial Trajectory Engine',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Desktop Navigation Tabs
                      if (showDesktopTabs) ...[
                        AppSpacing.hL,
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDesktopTab(
                                  context: context,
                                  title: 'Dashboard',
                                  icon: Icons.speed_rounded,
                                  isSelected: currentIndex == 0,
                                  onTap: () => _onTapDestination(0),
                                  theme: theme,
                                  brandColors: brandColors,
                                ),
                                AppSpacing.hXS,
                                _buildDesktopTab(
                                  context: context,
                                  title: 'Clearance',
                                  icon: Icons.credit_card_off_rounded,
                                  isSelected: currentIndex == 1,
                                  onTap: () => _onTapDestination(1),
                                  theme: theme,
                                  brandColors: brandColors,
                                ),
                                AppSpacing.hXS,
                                _buildDesktopTab(
                                  context: context,
                                  title: 'Milestones',
                                  icon: Icons.flag_rounded,
                                  isSelected: currentIndex == 2,
                                  onTap: () => _onTapDestination(2),
                                  theme: theme,
                                  brandColors: brandColors,
                                ),
                                AppSpacing.hXS,
                                _buildDesktopTab(
                                  context: context,
                                  title: 'Expenses',
                                  icon: Icons.receipt_long_rounded,
                                  isSelected: currentIndex == 3,
                                  badge: 'SOON',
                                  onTap: () => _onTapDestination(3),
                                  theme: theme,
                                  brandColors: brandColors,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),

                      AppSpacing.hS,
                      // Google Auth Profile Pill / Login CTA
                      UserProfilePill(isCompact: isCompactScreen),
                      AppSpacing.hS,
                      // Theme Mode Pill Toggle
                      const ThemeModeToggle(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : const Color(0x0C000000),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.22)
                        : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    height: 64,
                    elevation: 0,
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return IconThemeData(
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                          size: 22,
                        );
                      }
                      return IconThemeData(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 22,
                      );
                    }),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: AppFontWeight.bold,
                          letterSpacing: 0.2,
                        );
                      }
                      return TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: AppFontWeight.medium,
                        letterSpacing: 0.1,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: _onTapDestination,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.speed_outlined),
                        selectedIcon: Icon(Icons.speed_rounded),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.credit_card_outlined),
                        selectedIcon: Icon(Icons.credit_card_rounded),
                        label: 'Clearance',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.flag_outlined),
                        selectedIcon: Icon(Icons.flag_rounded),
                        label: 'Milestones',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_outlined),
                        selectedIcon: Icon(Icons.receipt_rounded),
                        label: 'Expenses',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopTab({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required BrandColors brandColors,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppBorderRadius.pill,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.hXS,
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected
                    ? AppFontWeight.bold
                    : AppFontWeight.medium,
              ),
            ),
            if (badge != null) ...[
              AppSpacing.hXXS,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs + 2,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: brandColors.milestone.withValues(alpha: 0.15),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: brandColors.milestone,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
