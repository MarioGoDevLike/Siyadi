import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/engagement.dart';
import '../../../data/models/user_profile.dart';

class ReputationRepository {
  ReputationRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  static String dayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Awards points with daily anti-spam caps. Idempotent when [sourceId] set.
  Future<bool> award({
    required String targetUid,
    required String actorUid,
    required ReputationAction action,
    String? sourceId,
  }) async {
    final day = dayKey();
    final awardId = sourceId != null
        ? '${targetUid}_${action.name}_$sourceId'
        : '${targetUid}_${action.name}_${actorUid}_$day';

    final awardRef = _db.collection('reputation_awards').doc(awardId);
    final dailyRef = _db
        .collection('reputation_daily')
        .doc('${targetUid}_${action.name}_$day');
    final userRef = _db.collection(FirestorePaths.users).doc(targetUid);

    try {
      var awarded = false;
      await _db.runTransaction((tx) async {
        final existing = await tx.get(awardRef);
        if (existing.exists) return;

        final dailySnap = await tx.get(dailyRef);
        final used = (dailySnap.data()?['count'] as num?)?.toInt() ?? 0;
        if (used >= action.dailyCap) return;

        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) return;
        final current =
            (userSnap.data()?['reputationPoints'] as num?)?.toInt() ?? 0;
        final next = current + action.points;
        final level = ReputationLevel.fromPoints(next);

        tx.set(awardRef, {
          'targetUid': targetUid,
          'actorUid': actorUid,
          'action': action.name,
          'points': action.points,
          'dayKey': day,
          'sourceId': sourceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(dailyRef, {
          'targetUid': targetUid,
          'action': action.name,
          'dayKey': day,
          'count': used + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(userRef, {
          'reputationPoints': next,
          'reputationLevel': level.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        awarded = true;
      });
      return awarded;
    } catch (_) {
      return false;
    }
  }
}

class BadgeRepository {
  BadgeRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<UserBadge>> watchUserBadges(String uid) {
    return _db
        .collection(FirestorePaths.userBadges)
        .where('userId', isEqualTo: uid)
        .limit(20)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserBadge.fromDoc).toList()
        ..sort((a, b) {
          final at = a.awardedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.awardedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      return list;
    });
  }

  Future<void> ensureBadge({
    required String userId,
    required String badgeId,
    required String badgeName,
  }) async {
    final id = '${userId}_$badgeId';
    final ref = _db.collection(FirestorePaths.userBadges).doc(id);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'userId': userId,
      'badgeId': badgeId,
      'badgeName': badgeName,
      'awardedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> countFieldReportsToday(String uid) async {
    final start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final snap = await _db
        .collection(FirestorePaths.fieldReports)
        .where('authorId', isEqualTo: uid)
        .where('reportDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .limit(10)
        .get();
    return snap.docs.length;
  }
}

class NotificationRepository {
  NotificationRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<AppNotification>> watchForUser(String uid) {
    return _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  Future<void> create({
    required String userId,
    required String type,
    required String title,
    String body = '',
    String? route,
  }) async {
    if (userId.isEmpty) return;
    await _db.collection(FirestorePaths.notifications).add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'route': route,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRead(String notificationId) async {
    await _db.collection(FirestorePaths.notifications).doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _db
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .limit(40)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    await _db.collection(FirestorePaths.users).doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
