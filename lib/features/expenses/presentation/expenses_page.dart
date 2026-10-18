import 'package:flutter/material.dart';
import '../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';

/// Full-screen workspace page establishing the upcoming Expenses workflow engine.
class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSpacing.m,
              tablet: AppSpacing.xl,
              desktop: AppSpacing.xxl,
            ),
            vertical: AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses & Outflows',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          'Track fixed subscriptions, living costs, and recurring burn rate.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.vL,

              // Metric Highlights Stubs
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  final fixedCard = VelocityMetricCard(
                    title: 'Fixed Subscriptions',
                    value: '₦0',
                    subtitle: 'Recurring monthly commitments',
                    icon: Icons.calendar_month_rounded,
                    accentColor: brandColors.milestone,
                  );

                  final dailyCard = VelocityMetricCard(
                    title: 'Daily Burn Rate',
                    value: '₦0 / day',
                    subtitle: 'Net outflow velocity',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: brandColors.debt,
                  );

                  final runwayCard = VelocityMetricCard(
                    title: 'Cash Runway',
                    value: '∞ Months',
                    subtitle: 'Based on current cash buffer',
                    icon: Icons.flight_takeoff_rounded,
                    accentColor: brandColors.progress,
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: fixedCard),
                        AppSpacing.hM,
                        Expanded(child: dailyCard),
                        AppSpacing.hM,
                        Expanded(child: runwayCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      fixedCard,
                      AppSpacing.vM,
                      dailyCard,
                      AppSpacing.vM,
                      runwayCard,
                    ],
                  );
                },
              ),
              AppSpacing.vXL,

              // Empty State / Roadmap Announcement Card
              VelocityEmptyStateCard(
                icon: Icons.receipt_long_rounded,
                iconColor: theme.colorScheme.primary,
                badgeLabel: 'EXPENSES WORKFLOW IN PROGRESS',
                badgeColor: theme.colorScheme.primary,
                title: 'Expenses Engine Coming Next',
                description:
                    'The expense tracking module is being wired to calculate daily capital outflow, recurring utility obligations, and exact net savings velocity.',
                actionLabel: 'Return to Executive Dashboard',
                onAction: () => Navigator.of(context).maybePop(),
              ),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }
}
