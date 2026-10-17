import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../domain/entities/transaction_entity.dart';
import 'controllers/ledger_controller.dart';

/// Presentation page displaying the financial transaction ledger.
class LedgerPage extends ConsumerWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(ledgerControllerProvider);
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Ledger'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => AppSpacing.vS,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isCredit = tx.type == TransactionType.income;
          final color = isCredit ? brandColors.progress : brandColors.debt;

          return Container(
            decoration: BoxDecoration(
              color: brandColors.surfaceCard,
              borderRadius: AppBorderRadius.allM,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(
                tx.note,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                '${isCredit ? '+' : '-'}${FinancialNumberFormatter.format(tx.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: AppFontWeight.bold,
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
