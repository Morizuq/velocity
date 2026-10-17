import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import 'controllers/clearance_controller.dart';
import 'widgets/debt_card.dart';

/// Presentation page for the Clearance bucket.
class ClearancePage extends ConsumerWidget {
  const ClearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(clearanceControllerProvider);
    final clearanceNotifier = ref.read(clearanceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clearance Bucket'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.l),
        itemCount: debts.length,
        separatorBuilder: (context, index) => AppSpacing.vM,
        itemBuilder: (context, index) {
          final debt = debts[index];
          return DebtCard(
            debt: debt,
            onLogPayment: (amount) => clearanceNotifier.logPayment(debt.id, amount),
            onToggleCleared: () => clearanceNotifier.toggleCleared(debt.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allXL),
        onPressed: () {
          clearanceNotifier.addDebt(
            creditor: 'New Creditor',
            totalOwed: 50000,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
