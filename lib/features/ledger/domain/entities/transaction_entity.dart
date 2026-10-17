import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  debtPayment,
  goalFunding,
  expense,
}

/// Pure domain entity representing a ledger transaction entry.
@immutable
class TransactionEntity {
  final String id;
  final TransactionType type;
  final double amount;
  final String? referenceId;
  final DateTime date;
  final String note;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.referenceId,
    required this.date,
    required this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          amount == other.amount &&
          referenceId == other.referenceId &&
          date == other.date &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, type, amount, referenceId, date, note);
}
