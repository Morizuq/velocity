import 'package:flutter/foundation.dart';
import 'receivable_type.dart';

/// Pure domain entity representing money owed to the user (Accounts Receivable).
@immutable
class ReceivableEntity {
  final String id;

  /// The individual, client, or company owing the balance.
  final String debtor;

  final double totalAmount;
  final double amountReceived;
  final ReceivableType type;
  final bool isSettled;
  final DateTime? dueDate;
  final DateTime issueDate;

  /// Optional service, project, or claim description (e.g. 'Web App Redesign').
  final String? description;

  /// Optional tracking identifier for freelance billing.
  final String? invoiceNumber;
  final String? notes;

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
  bool get isOverdue =>
      hasDueDate && !isSettled && dueDate!.isBefore(DateTime.now());

  /// Whether the receivable is expected within the upcoming 7 days.
  bool get isDueSoon {
    if (!hasDueDate || isSettled || isOverdue) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  /// Days remaining until settlement is due.
  int? get daysUntilDue {
    if (!hasDueDate) return null;
    return dueDate!.difference(DateTime.now()).inDays;
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
  };

  factory ReceivableEntity.fromMap(Map<String, dynamic> map) => ReceivableEntity(
    id: map['id'] as String,
    debtor: map['debtor'] as String,
    totalAmount: (map['totalAmount'] as num).toDouble(),
    amountReceived: (map['amountReceived'] as num).toDouble(),
    type: ReceivableType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => ReceivableType.personalLoan,
    ),
    isSettled: map['isSettled'] as bool? ?? false,
    issueDate: DateTime.parse(map['issueDate'] as String),
    dueDate: map['dueDate'] != null
        ? DateTime.tryParse(map['dueDate'] as String)
        : null,
    description: map['description'] as String?,
    invoiceNumber: map['invoiceNumber'] as String?,
    notes: map['notes'] as String?,
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
          invoiceNumber == other.invoiceNumber;

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
  );
}
