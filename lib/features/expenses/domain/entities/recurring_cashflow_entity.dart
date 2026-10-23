import 'package:flutter/foundation.dart';
import 'cashflow_direction.dart';

/// Pure domain entity representing an ongoing monthly payable or recurring income flow.
@immutable
class RecurringCashflowEntity {
  final String id;
  final String title;
  final double amount;
  final CashflowDirection direction;

  /// Day of the month on which this item is charged or paid (1..31).
  final int dayOfMonth;

  /// Category classification (e.g. Utility, Subscription, Housing, Salary, Freelance Retainer).
  final String category;

  /// The calendar month key in which this item was last settled (e.g. '2026-10').
  final String? lastSettledCycle;

  final int sortIndex;

  /// Optional expiration date for fixed-term gigs or contracts. Null if indefinite.
  final DateTime? endDate;

  final String? notes;

  const RecurringCashflowEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.direction,
    required this.dayOfMonth,
    required this.category,
    this.sortIndex = 0,
    this.lastSettledCycle,
    this.endDate,
    this.notes,
  }) : assert(amount > 0, 'Amount must be greater than zero'),
       assert(dayOfMonth >= 0 && dayOfMonth <= 31, 'dayOfMonth must be 0..31');

  /// Generates the standard cycle key for a given calendar moment (e.g. '2026-10').
  static String currentCycleKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Whether this cashflow item has already been settled for the current calendar cycle.
  bool get isSettledThisMonth => lastSettledCycle == currentCycleKey();

  /// Computes the exact [DateTime] of the next upcoming billing/payment event.
  DateTime nextDueDate([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    if (dayOfMonth <= 0) return now;
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = dayOfMonth.clamp(1, daysInCurrentMonth);
    final targetDateThisMonth = DateTime(now.year, now.month, clampedDay);

    if (now.isAfter(targetDateThisMonth) && isSettledThisMonth) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      return DateTime(
        nextYear,
        nextMonth,
        dayOfMonth.clamp(1, daysInNextMonth),
      );
    }
    return targetDateThisMonth;
  }

  /// Calculates days until the upcoming due date relative to the given reference date.
  int daysUntilDue([DateTime? fromDate]) {
    if (dayOfMonth <= 0) return 0;
    final now = fromDate ?? DateTime.now();
    final due = nextDueDate(now);
    final todayClean = DateTime(now.year, now.month, now.day);
    final dueClean = DateTime(due.year, due.month, due.day);
    return dueClean.difference(todayClean).inDays;
  }

  /// Indicates if payment/receipt is scheduled for today.
  bool get isDueToday => dayOfMonth > 0 && daysUntilDue() == 0;

  /// Indicates if this item's target day has passed in the current month without being settled.
  bool get isOverdue => dayOfMonth > 0 && !isSettledThisMonth && daysUntilDue() < 0;

  /// Returns a copy marked as settled for the active calendar cycle.
  RecurringCashflowEntity markSettledForCurrentCycle() {
    return copyWith(lastSettledCycle: currentCycleKey());
  }

  /// Returns a copy marked as unsettled.
  RecurringCashflowEntity unmarkSettled() {
    return copyWith(clearLastSettledCycle: true);
  }

  RecurringCashflowEntity copyWith({
    String? id,
    String? title,
    double? amount,
    CashflowDirection? direction,
    int? dayOfMonth,
    String? category,
    int? sortIndex,
    String? lastSettledCycle,
    DateTime? endDate,
    String? notes,
    bool clearLastSettledCycle = false,
  }) {
    return RecurringCashflowEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      category: category ?? this.category,
      sortIndex: sortIndex ?? this.sortIndex,
      lastSettledCycle: clearLastSettledCycle
          ? null
          : (lastSettledCycle ?? this.lastSettledCycle),
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'direction': direction.name,
    'dayOfMonth': dayOfMonth,
    'category': category,
    'sortIndex': sortIndex,
    'lastSettledCycle': lastSettledCycle,
    'endDate': endDate?.toIso8601String(),
    'notes': notes,
  };

  factory RecurringCashflowEntity.fromMap(Map<String, dynamic> map) =>
      RecurringCashflowEntity(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        direction: CashflowDirection.values.firstWhere(
          (e) => e.name == map['direction'],
          orElse: () => CashflowDirection.outflowPayable,
        ),
        dayOfMonth: map['dayOfMonth'] as int? ?? 0,
        category: map['category'] as String? ?? 'General',
        sortIndex: map['sortIndex'] as int? ?? 0,
        lastSettledCycle: map['lastSettledCycle'] as String?,
        endDate: map['endDate'] != null
            ? DateTime.tryParse(map['endDate'] as String)
            : null,
        notes: map['notes'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringCashflowEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount &&
          direction == other.direction &&
          dayOfMonth == other.dayOfMonth &&
          category == other.category &&
          sortIndex == other.sortIndex &&
          lastSettledCycle == other.lastSettledCycle &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amount,
    direction,
    dayOfMonth,
    category,
    sortIndex,
    lastSettledCycle,
    endDate,
  );
}
