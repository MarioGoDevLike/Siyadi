import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/user_profile.dart';

class FollowRepository {
  FollowRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  static String followId(String followerId, String followingId) =>
      '${followerId}_$followingId';

  DocumentReference<Map<String, dynamic>> _followRef(
    String followerId,
    String followingId,
  ) {
    return _db
        .collection(FirestorePaths.follows)
        .doc(followId(followerId, followingId));
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db.collection(FirestorePaths.users).doc(uid);
  }

  Stream<bool> watchIsFollowing({
    required String followerId,
    required String followingId,
  }) {
    return _followRef(followerId, followingId).snapshots().map((s) => s.exists);
  }

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final snap = await _followRef(followerId, followingId).get();
    return snap.exists;
  }

  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) {
      throw FollowException('You cannot follow yourself.');
    }

    await _db.runTransaction((tx) async {
      final followSnap = await tx.get(_followRef(followerId, followingId));
      if (followSnap.exists) return;

      final followerSnap = await tx.get(_userRef(followerId));
      final followingSnap = await tx.get(_userRef(followingId));
      if (!followerSnap.exists || !followingSnap.exists) {
        throw FollowException('User profile not found.');
      }

      tx.set(_followRef(followerId, followingId), {
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(_userRef(followerId), {
        'followingCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(_userRef(followingId), {
        'followersCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    await _db.runTransaction((tx) async {
      final followSnap = await tx.get(_followRef(followerId, followingId));
      if (!followSnap.exists) return;

      final followerSnap = await tx.get(_userRef(followerId));
      final followingSnap = await tx.get(_userRef(followingId));

      tx.delete(_followRef(followerId, followingId));

      if (followerSnap.exists) {
        final followingCount =
            (followerSnap.data()?['followingCount'] as num?)?.toInt() ?? 0;
        if (followingCount > 0) {
          tx.update(_userRef(followerId), {
            'followingCount': followingCount - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (followingSnap.exists) {
        final followersCount =
            (followingSnap.data()?['followersCount'] as num?)?.toInt() ?? 0;
        if (followersCount > 0) {
          tx.update(_userRef(followingId), {
            'followersCount': followersCount - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  /// People who follow [uid].
  Stream<List<String>> watchFollowerIds(String uid) {
    return _db
        .collection(FirestorePaths.follows)
        .where('followingId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => d.data()['followerId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  /// People [uid] follows.
  Stream<List<String>> watchFollowingIds(String uid) {
    return _db
        .collection(FirestorePaths.follows)
        .where('followerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => d.data()['followingId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  Future<List<UserProfile>> loadProfiles(List<String> uids) async {
    if (uids.isEmpty) return const [];
    final profiles = <UserProfile>[];
    // Firestore whereIn limit is 30 — chunk if needed.
    for (var i = 0; i < uids.length; i += 30) {
      final chunk = uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
      final snap = await _db
          .collection(FirestorePaths.users)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      profiles.addAll(
        snap.docs.map(UserProfile.fromDoc),
      );
    }
    // Preserve input order.
    final byId = {for (final p in profiles) p.uid: p};
    return uids.map((id) => byId[id]).whereType<UserProfile>().toList();
  }
}

class FollowException implements Exception {
  FollowException(this.message);
  final String message;

  @override
  String toString() => message;
}
