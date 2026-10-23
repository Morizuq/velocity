import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/milestone_entity.dart';

/// State notifier managing milestone savings targets, fund adjustments, local persistence,
/// and live cloud synchronization across devices.
class MilestonesController extends Notifier<List<MilestoneEntity>> {
  static const _storageKey = 'velocity_milestones';
  StreamSubscription<List<MilestoneEntity>>? _firestoreSub;
  String? _currentUid;

  @override
  List<MilestoneEntity> build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localMilestones = _loadLocal();

    // Listen for auth state transitions
    ref.listen<AsyncValue<UserEntity?>>(authStateChangesProvider, (prev, next) {
      final user = next.asData?.value;
      if (user?.id != _currentUid) {
        _currentUid = user?.id;
        _onAuthChanged(user?.id);
      }
    });

    final initialUser = ref.read(authStateChangesProvider).asData?.value;
    _currentUid = initialUser?.id;
    if (_currentUid != null) {
      Future.microtask(() => _onAuthChanged(_currentUid));
    }

    return localMilestones;
  }

  List<MilestoneEntity> _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => MilestoneEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  void _onAuthChanged(String? uid) {
    _firestoreSub?.cancel();
    _firestoreSub = null;

    if (uid == null) return;

    final syncService = ref.read(firestoreSyncServiceProvider);

    if (state.isNotEmpty) {
      syncService.syncMilestones(uid, state);
    }

    _firestoreSub = syncService.watchMilestones(uid).listen((remoteMilestones) {
      if (remoteMilestones.isNotEmpty || state.isEmpty) {
        state = remoteMilestones;
        _persist(remoteMilestones, pushToCloud: false);
      }
    });
  }

  void _persist(List<MilestoneEntity> updated, {bool pushToCloud = true}) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((m) => m.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref
          .read(firestoreSyncServiceProvider)
          .syncMilestones(_currentUid!, updated);
    }
  }

  /// Allocates savings funds towards an upcoming milestone purchase.
  void allocateFunds(String milestoneId, double amount) {
    adjustFunds(milestoneId, amount);
  }

  /// Adjusts funds by a positive or negative delta (e.g. depositing or removing funds).
  void adjustFunds(String milestoneId, double deltaAmount) {
    final updated = [
      for (final milestone in state)
        if (milestone.id == milestoneId)
          milestone.copyWith(
            currentAmount: (milestone.currentAmount + deltaAmount).clamp(
              0.0,
              milestone.targetAmount,
            ),
          )
        else
          milestone,
    ];
    state = updated;
    _persist(updated);
  }

  /// Sets the milestone accumulated balance directly to a specific value.
  void setMilestoneAmount(String milestoneId, double newAmount) {
    final updated = [
      for (final milestone in state)
        if (milestone.id == milestoneId)
          milestone.copyWith(
            currentAmount: newAmount.clamp(0.0, milestone.targetAmount),
          )
        else
          milestone,
    ];
    state = updated;
    _persist(updated);
  }

  List<MilestoneEntity> _renumber(List<MilestoneEntity> list) {
    return [
      for (int i = 0; i < list.length; i++) list[i].copyWith(sortIndex: i),
    ];
  }

  /// Adds a new milestone savings goal.
  void addMilestone({
    required String title,
    required double targetAmount,
    double initialAmount = 0.0,
  }) {
    final newMilestone = MilestoneEntity(
      id: 'milestone_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      isCompleted: initialAmount >= targetAmount && targetAmount > 0,
      sortIndex: state.length,
    );
    final updated = [...state, newMilestone];
    state = updated;
    _persist(updated);
  }

  /// Updates an existing milestone.
  void updateMilestone(MilestoneEntity updatedEntity) {
    final updated = [
      for (final m in state)
        if (m.id == updatedEntity.id) updatedEntity else m,
    ];
    state = updated;
    _persist(updated);
  }

  /// Restores a deleted milestone (for Undo toast).
  void restoreMilestone(MilestoneEntity milestone, int targetIndex) {
    final list = List<MilestoneEntity>.from(state);
    final insertIdx = targetIndex.clamp(0, list.length);
    list.insert(insertIdx, milestone);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  /// Deletes a milestone from local storage and Cloud Firestore.
  void deleteMilestone(String milestoneId) {
    final updated = state.where((m) => m.id != milestoneId).toList();
    final renumbered = _renumber(updated);
    state = renumbered;
    _persist(renumbered, pushToCloud: false);
    if (_currentUid != null) {
      ref
          .read(firestoreSyncServiceProvider)
          .deleteMilestone(_currentUid!, milestoneId);
    }
  }

  /// Moves a milestone by button action (direction: 'top', 'up', 'down').
  void move(int index, String direction) {
    if (index < 0 || index >= state.length) return;
    final list = List<MilestoneEntity>.from(state);
    final item = list.removeAt(index);
    int target;
    if (direction == 'top') {
      target = 0;
    } else if (direction == 'up') {
      target = (index - 1).clamp(0, list.length);
    } else {
      target = (index + 1).clamp(0, list.length);
    }
    list.insert(target, item);
    final renumbered = _renumber(list);
    state = renumbered;
    _persist(renumbered);
  }

  /// Reorders milestones when dragged and dropped, updating local and cloud sequence.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex > state.length) return;
    if (oldIndex == newIndex) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updated = List<MilestoneEntity>.from(state);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    final renumbered = _renumber(updated);
    state = renumbered;
    _persist(renumbered);
  }

  /// Clears all milestone entities.
  void clearAll() {
    state = const [];
    _persist(const []);
  }
}

final milestonesControllerProvider =
    NotifierProvider<MilestonesController, List<MilestoneEntity>>(
      MilestonesController.new,
    );

/// Provider computing total target savings across all milestone goals.
final totalMilestoneTargetProvider = Provider<double>((ref) {
  final milestones = ref.watch(milestonesControllerProvider);
  return milestones.fold<double>(0.0, (sum, m) => sum + m.targetAmount);
});

/// Provider computing total accumulated milestone savings.
final totalMilestoneSavedProvider = Provider<double>((ref) {
  final milestones = ref.watch(milestonesControllerProvider);
  return milestones.fold<double>(0.0, (sum, m) => sum + m.currentAmount);
});
