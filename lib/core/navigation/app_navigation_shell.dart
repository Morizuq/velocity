import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/widgets/user_profile_pill.dart';
import '../../features/dashboard/presentation/widgets/theme_mode_toggle.dart';
import '../../shared/design_system/tokens/app_border_radius.dart';
import '../../shared/design_system/tokens/app_spacing.dart';
import '../theme/velocity_tokens.dart';
import 'widgets/header_data_sync_button.dart';

/// Navigation shell adhering strictly to the Velocity Redesign specification:
/// - Max-width 880px container
/// - Header with 22px Bricolage Grotesque title, ghost Theme button, and auth pill
/// - Safe-area insets respected
/// - Bottom navigation bar hosting: Overview, Monthly, Debts, Owed, Goals
/// - 44px minimum tap targets
class AppNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({super.key, required this.navigationShell});

  void _onTapDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.bg,
            border: Border(bottom: BorderSide(color: tokens.line, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageMargin,
                  ),
                  child: Row(
                    children: [
                      // Header Brand Title
                      InkWell(
                        onTap: () => _onTapDestination(0),
                        borderRadius: AppBorderRadius.allButton,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Velocity',
                            style: tokens.bricolage(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Theme Switch Toggle
                      const ThemeModeToggle(),
                      AppSpacing.hXS,

                      // Data Backup / Transfer Button
                      const HeaderDataSyncButton(),
                      AppSpacing.hXS,

                      // User Profile Pill / Auth
                      const UserProfilePill(isCompact: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 64 + MediaQuery.paddingOf(context).bottom,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.line, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    _buildTabButton(
                      context: context,
                      title: 'Overview',
                      icon: Icons.speed_rounded,
                      index: 0,
                      currentIndex: currentIndex,
                      tokens: tokens,
                    ),
                    _buildTabButton(
                      context: context,
                      title: 'Monthly',
                      icon: Icons.calendar_today_rounded,
                      index: 1,
                      currentIndex: currentIndex,
                      tokens: tokens,
                    ),
                    _buildTabButton(
                      context: context,
                      title: 'Debts',
                      icon: Icons.credit_card_outlined,
                      index: 2,
                      currentIndex: currentIndex,
                      tokens: tokens,
                    ),
                    _buildTabButton(
                      context: context,
                      title: 'Owed',
                      icon: Icons.account_balance_wallet_outlined,
                      index: 3,
                      currentIndex: currentIndex,
                      tokens: tokens,
                    ),
                    _buildTabButton(
                      context: context,
                      title: 'Goals',
                      icon: Icons.flag_outlined,
                      index: 4,
                      currentIndex: currentIndex,
                      tokens: tokens,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int index,
    required int currentIndex,
    required VelocityTokens tokens,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$title tab',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onTapDestination(index),
          child: Container(
            height: 48, // Meets 44px min touch target
            decoration: BoxDecoration(
              color: isSelected ? tokens.soft : Colors.transparent,
              borderRadius: AppBorderRadius.allButton,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? tokens.accent : tokens.mute,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.figtree(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? tokens.accent : tokens.mute,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
