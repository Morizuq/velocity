import 'package:flutter/foundation.dart';

/// Pure domain entity representing an upcoming big purchase or savings milestone.
@immutable
class MilestoneEntity {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;

  const MilestoneEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.isCompleted = false,
  });

  /// Remaining amount needed to fulfill this milestone.
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, targetAmount);

  /// Fractional progress between 0.0 and 1.0.
  double get progressRatio {
    if (targetAmount <= 0) return 1.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Percentage completed formatted as integer.
  int get progressPercentage => (progressRatio * 100).round();

  MilestoneEntity copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    bool? isCompleted,
  }) {
    final updatedCurrent = currentAmount ?? this.currentAmount;
    final updatedTarget = targetAmount ?? this.targetAmount;
    final automaticallyCompleted = updatedCurrent >= updatedTarget && updatedTarget > 0;

    return MilestoneEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: updatedTarget,
      currentAmount: updatedCurrent,
      isCompleted: isCompleted ?? automaticallyCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'isCompleted': isCompleted,
      };

  factory MilestoneEntity.fromMap(Map<String, dynamic> map) => MilestoneEntity(
        id: map['id'] as String,
        title: map['title'] as String,
        targetAmount: (map['targetAmount'] as num).toDouble(),
        currentAmount: (map['currentAmount'] as num).toDouble(),
        isCompleted: map['isCompleted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(id, title, targetAmount, currentAmount, isCompleted);
}
