import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/asset_entity.dart';

/// State notifier managing high-value long-term wealth asset goals, local persistence,
/// and live cloud synchronization across devices.
class AssetsController extends Notifier<List<AssetEntity>> {
  static const _storageKey = 'velocity_assets';
  StreamSubscription<List<AssetEntity>>? _firestoreSub;
  String? _currentUid;

  @override
  List<AssetEntity> build() {
    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    final localAssets = _loadLocal();

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

    return localAssets;
  }

  List<AssetEntity> _loadLocal() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => AssetEntity.fromMap(e as Map<String, dynamic>))
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
      syncService.syncAssets(uid, state);
    }

    _firestoreSub = syncService.watchAssets(uid).listen((remoteAssets) {
      if (remoteAssets.isNotEmpty || state.isEmpty) {
        state = remoteAssets;
        _persist(remoteAssets, pushToCloud: false);
      }
    });
  }

  void _persist(List<AssetEntity> updated, {bool pushToCloud = true}) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((a) => a.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}

    if (pushToCloud && _currentUid != null) {
      ref.read(firestoreSyncServiceProvider).syncAssets(_currentUid!, updated);
    }
  }

  /// Allocates or adjusts capital towards long-term asset acquisition.
  void allocateCapital(String assetId, double amount) {
    adjustCapital(assetId, amount);
  }

  /// Adjusts capital by a positive or negative delta.
  void adjustCapital(String assetId, double delta) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: (asset.currentAmount + delta).clamp(
              0.0,
              asset.targetAmount,
            ),
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Directly overrides the accumulated capital balance.
  void setAssetAmount(String assetId, double newAmount) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: newAmount.clamp(0.0, asset.targetAmount),
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Marks an asset as purchased or acquired.
  void markPurchased(String assetId) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: asset.targetAmount,
            isCompleted: true,
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Toggles purchased status.
  void togglePurchased(String assetId) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            isCompleted: !asset.isCompleted,
            currentAmount: !asset.isCompleted
                ? asset.targetAmount
                : asset.currentAmount,
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Adds a new overarching wealth asset.
  void addAsset({
    required String title,
    required double targetAmount,
    double initialAmount = 0.0,
  }) {
    final newAsset = AssetEntity(
      id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      isCompleted: initialAmount >= targetAmount && targetAmount > 0,
    );
    final updated = [...state, newAsset];
    state = updated;
    _persist(updated);
  }

  /// Deletes an asset goal from local storage and Cloud Firestore.
  void deleteAsset(String assetId) {
    final updated = state.where((a) => a.id != assetId).toList();
    state = updated;
    _persist(updated, pushToCloud: false);
    if (_currentUid != null) {
      ref.read(firestoreSyncServiceProvider).deleteAsset(_currentUid!, assetId);
    }
  }
}

final assetsControllerProvider =
    NotifierProvider<AssetsController, List<AssetEntity>>(
      AssetsController.new,
    );

/// Provider computing total target valuation across all logged long-term assets.
final totalAssetValuationTargetProvider = Provider<double>((ref) {
  final assets = ref.watch(assetsControllerProvider);
  return assets.fold<double>(0.0, (sum, a) => sum + a.targetAmount);
});
final totalAssetTargetProvider = totalAssetValuationTargetProvider;

/// Provider computing total secured capital accumulated across all wealth goals.
final totalCapitalSecuredProvider = Provider<double>((ref) {
  final assets = ref.watch(assetsControllerProvider);
  return assets.fold<double>(0.0, (sum, a) => sum + a.currentAmount);
});
final totalAssetSavedProvider = totalCapitalSecuredProvider;

/// Provider returning the total count of registered asset goals.
final activeAssetCountProvider = Provider<int>((ref) {
  final assets = ref.watch(assetsControllerProvider);
  return assets.length;
});

/// Overall wealth progression ratio across all recorded long-term assets.
final overallAssetVelocityRatioProvider = Provider<double>((ref) {
  final target = ref.watch(totalAssetValuationTargetProvider);
  final secured = ref.watch(totalCapitalSecuredProvider);
  if (target <= 0) return 0.0;
  return (secured / target).clamp(0.0, 1.0);
});
