import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';

/// State notifier managing transaction history in the financial ledger.
class LedgerController extends Notifier<List<TransactionEntity>> {
  @override
  List<TransactionEntity> build() {
    return [
      TransactionEntity(
        id: 'tx_1',
        type: TransactionType.income,
        amount: 250000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        note: 'Consulting Retainer Milestone 1',
      ),
      TransactionEntity(
        id: 'tx_2',
        type: TransactionType.debtPayment,
        amount: 30000,
        referenceId: 'debt_kuda',
        date: DateTime.now().subtract(const Duration(days: 3)),
        note: 'Payment to Kuda Account',
      ),
      TransactionEntity(
        id: 'tx_3',
        type: TransactionType.goalFunding,
        amount: 50000,
        referenceId: 'milestone_workspace',
        date: DateTime.now().subtract(const Duration(days: 5)),
        note: 'Ergonomic Desk Fund Allocation',
      ),
    ];
  }

  void recordTransaction(TransactionEntity transaction) {
    state = [transaction, ...state];
  }
}

final ledgerControllerProvider =
    NotifierProvider<LedgerController, List<TransactionEntity>>(
  LedgerController.new,
);
