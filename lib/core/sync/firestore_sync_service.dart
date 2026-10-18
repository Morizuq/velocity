import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/assets/domain/entities/asset_entity.dart';
import '../../features/clearance/domain/entities/debt_entity.dart';
import '../../features/milestones/domain/entities/milestone_entity.dart';

/// Service responsible for real-time bi-directional synchronization
/// between local state and Cloud Firestore under users/{uid}/...
class FirestoreSyncService {
  final FirebaseFirestore? _firestore;

  FirestoreSyncService({this._firestore});

  bool get _canSync {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userClearance(String uid) =>
      _db.collection('users').doc(uid).collection('clearance');

  CollectionReference<Map<String, dynamic>> _userMilestones(String uid) =>
      _db.collection('users').doc(uid).collection('milestones');

  CollectionReference<Map<String, dynamic>> _userAssets(String uid) =>
      _db.collection('users').doc(uid).collection('assets');

  DocumentReference<Map<String, dynamic>> _userOverview(String uid) =>
      _db.collection('users').doc(uid).collection('profile').doc('overview');

  // ================= CLEARANCE DEBTS =================

  Stream<List<DebtEntity>> watchDebts(String uid) {
    if (!_canSync) return const Stream.empty();
    try {
      return _userClearance(uid).snapshots().map((snapshot) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aOrder = a.data()['orderIndex'] as num? ?? 999999;
          final bOrder = b.data()['orderIndex'] as num? ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        return docs.map((doc) => DebtEntity.fromMap(doc.data())).toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> syncDebts(String uid, List<DebtEntity> debts) async {
    if (!_canSync) return;
    try {
      final batch = _db.batch();
      final col = _userClearance(uid);
      for (int i = 0; i < debts.length; i++) {
        final data = debts[i].toMap();
        data['orderIndex'] = i;
        batch.set(col.doc(debts[i].id), data, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteDebt(String uid, String debtId) async {
    if (!_canSync) return;
    try {
      await _userClearance(uid).doc(debtId).delete();
    } catch (_) {}
  }

  // ================= MILESTONES =================

  Stream<List<MilestoneEntity>> watchMilestones(String uid) {
    if (!_canSync) return const Stream.empty();
    try {
      return _userMilestones(uid).snapshots().map((snapshot) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aOrder = a.data()['orderIndex'] as num? ?? 999999;
          final bOrder = b.data()['orderIndex'] as num? ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        return docs.map((doc) => MilestoneEntity.fromMap(doc.data())).toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> syncMilestones(
    String uid,
    List<MilestoneEntity> milestones,
  ) async {
    if (!_canSync) return;
    try {
      final batch = _db.batch();
      final col = _userMilestones(uid);
      for (int i = 0; i < milestones.length; i++) {
        final data = milestones[i].toMap();
        data['orderIndex'] = i;
        batch.set(col.doc(milestones[i].id), data, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteMilestone(String uid, String milestoneId) async {
    if (!_canSync) return;
    try {
      await _userMilestones(uid).doc(milestoneId).delete();
    } catch (_) {}
  }

  // ================= ASSETS =================

  Stream<List<AssetEntity>> watchAssets(String uid) {
    if (!_canSync) return const Stream.empty();
    try {
      return _userAssets(uid).snapshots().map((snapshot) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aOrder = a.data()['orderIndex'] as num? ?? 999999;
          final bOrder = b.data()['orderIndex'] as num? ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        return docs.map((doc) => AssetEntity.fromMap(doc.data())).toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> syncAssets(String uid, List<AssetEntity> assets) async {
    if (!_canSync) return;
    try {
      final batch = _db.batch();
      final col = _userAssets(uid);
      for (int i = 0; i < assets.length; i++) {
        final data = assets[i].toMap();
        data['orderIndex'] = i;
        batch.set(col.doc(assets[i].id), data, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> deleteAsset(String uid, String assetId) async {
    if (!_canSync) return;
    try {
      await _userAssets(uid).doc(assetId).delete();
    } catch (_) {}
  }

  // ================= LIQUID CASH =================

  Stream<double?> watchLiquidCash(String uid) {
    if (!_canSync) return const Stream.empty();
    try {
      return _userOverview(uid).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data();
        final val = data?['liquidCash'];
        if (val is num) return val.toDouble();
        return null;
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> syncLiquidCash(String uid, double amount) async {
    if (!_canSync) return;
    try {
      await _userOverview(uid).set({
        'liquidCash': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});
