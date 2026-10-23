import 'package:flutter/foundation.dart';
import 'receivable_type.dart';

/// Pure domain entity representing money owed to the user (Accounts Receivable).
@immutable
class ReceivableEntity {
  final String id;
  final String debtor;
  final double totalAmount;
  final double amountReceived;
  final ReceivableType type;
  final bool isSettled;
  final DateTime? dueDate;
  final DateTime issueDate;
  final String? description;
  final String? invoiceNumber;
  final String? notes;
  final int sortIndex;

  const ReceivableEntity({
    required this.id,
    required this.debtor,
    required this.totalAmount,
    required this.amountReceived,
    required this.type,
    required this.issueDate,
    this.isSettled = false,
    this.dueDate,
    this.description,
    this.invoiceNumber,
    this.notes,
    this.sortIndex = 0,
  }) : assert(totalAmount >= 0, 'totalAmount must be non-negative'),
       assert(amountReceived >= 0, 'amountReceived must be non-negative');

  /// Outstanding balance still owed to the user.
  double get remainingBalance =>
      (totalAmount - amountReceived).clamp(0.0, totalAmount);

  /// Fraction of funds collected between 0.0 and 1.0.
  double get collectionProgress {
    if (totalAmount <= 0) return 1.0;
    return (amountReceived / totalAmount).clamp(0.0, 1.0);
  }

  /// Percentage completed formatted as integer.
  int get progressPercentage => (collectionProgress * 100).round();

  /// Whether a due date is specified.
  bool get hasDueDate => dueDate != null;

  /// Whether the receivable is past its expected repayment date and remains unsettled.
  bool get isOverdue {
    if (!hasDueDate || isSettled || remainingBalance <= 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  /// Calculates days late relative to the current real date.
  int get daysLate {
    if (!hasDueDate || isSettled || remainingBalance <= 0) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Whether the receivable is expected within the upcoming 7 days.
  bool get isDueSoon {
    if (!hasDueDate || isSettled || isOverdue) return false;
    final diff = daysUntilDue;
    return diff != null && diff >= 0 && diff <= 7;
  }

  /// Days remaining until settlement is due.
  int? get daysUntilDue {
    if (!hasDueDate) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  ReceivableEntity copyWith({
    String? id,
    String? debtor,
    double? totalAmount,
    double? amountReceived,
    ReceivableType? type,
    bool? isSettled,
    DateTime? dueDate,
    DateTime? issueDate,
    String? description,
    String? invoiceNumber,
    String? notes,
    int? sortIndex,
    bool clearDueDate = false,
    bool clearDescription = false,
    bool clearInvoiceNumber = false,
  }) {
    final updatedReceived = amountReceived ?? this.amountReceived;
    final updatedTotal = totalAmount ?? this.totalAmount;
    final autoSettled = updatedReceived >= updatedTotal && updatedTotal > 0;

    return ReceivableEntity(
      id: id ?? this.id,
      debtor: debtor ?? this.debtor,
      totalAmount: updatedTotal,
      amountReceived: updatedReceived,
      type: type ?? this.type,
      isSettled: isSettled ?? autoSettled,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      issueDate: issueDate ?? this.issueDate,
      description: clearDescription
          ? null
          : (description ?? this.description),
      invoiceNumber: clearInvoiceNumber
          ? null
          : (invoiceNumber ?? this.invoiceNumber),
      notes: notes ?? this.notes,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'debtor': debtor,
    'totalAmount': totalAmount,
    'amountReceived': amountReceived,
    'type': type.name,
    'isSettled': isSettled,
    'issueDate': issueDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'description': description,
    'invoiceNumber': invoiceNumber,
    'notes': notes,
    'sortIndex': sortIndex,
  };

  factory ReceivableEntity.fromMap(Map<String, dynamic> map) => ReceivableEntity(
    id: map['id'] as String,
    debtor: (map['debtor'] ?? map['n'] ?? '') as String,
    totalAmount: ((map['totalAmount'] ?? map['t'] ?? map['amount'] ?? 0.0) as num).toDouble(),
    amountReceived: ((map['amountReceived'] ?? map['p'] ?? map['received'] ?? 0.0) as num).toDouble(),
    type: ReceivableType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ReceivableType.personalLoan,
    ),
    isSettled: map['isSettled'] as bool? ?? false,
    issueDate: map['issueDate'] != null
        ? DateTime.parse(map['issueDate'] as String)
        : DateTime.now(),
    dueDate: map['dueDate'] != null
        ? DateTime.tryParse(map['dueDate'] as String)
        : (map['d'] != null ? DateTime.tryParse(map['d'] as String) : null),
    description: map['description'] as String?,
    invoiceNumber: map['invoiceNumber'] as String?,
    notes: map['notes'] as String?,
    sortIndex: (map['sortIndex'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          debtor == other.debtor &&
          totalAmount == other.totalAmount &&
          amountReceived == other.amountReceived &&
          type == other.type &&
          isSettled == other.isSettled &&
          dueDate == other.dueDate &&
          issueDate == other.issueDate &&
          description == other.description &&
          invoiceNumber == other.invoiceNumber &&
          notes == other.notes &&
          sortIndex == other.sortIndex;

  @override
  int get hashCode => Object.hash(
    id,
    debtor,
    totalAmount,
    amountReceived,
    type,
    isSettled,
    dueDate,
    issueDate,
    description,
    invoiceNumber,
    notes,
    sortIndex,
  );
}
