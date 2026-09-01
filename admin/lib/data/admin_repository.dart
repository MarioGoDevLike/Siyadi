import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminRepository {
  AdminRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;
  bool _googleReady = false;

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  Stream<User?> watchAuth() => _auth.authStateChanges();

  Future<bool> isAdmin(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['isAdmin'] == true;
  }

  Stream<bool> watchIsAdmin(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (s) => s.data()?['isAdmin'] == true,
        );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogle();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw AdminException('Google Sign-In did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _ensureGoogle();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> watchPendingLocations({
    String country = 'Lebanon',
  }) {
    return _db
        .collection('hunting_locations')
        .where('status', isEqualTo: 'pending')
        .where('country', isEqualTo: country)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Future<void> reviewLocation({
    required String locationId,
    required String status,
    required String reviewerUid,
    String? note,
  }) async {
    final locRef = _db.collection('hunting_locations').doc(locationId);
    final locSnap = await locRef.get();
    final data = locSnap.data() ?? {};
    final proposedBy = data['proposedBy'] as String? ?? '';
    final locationName = data['name'] as String? ?? 'Location';
    final approved = status == 'approved';

    await locRef.update({
      'status': status,
      'reviewNote': note,
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (proposedBy.isEmpty) return;

    await _db.collection('notifications').add({
      'userId': proposedBy,
      'type': 'location_review',
      'title': approved
          ? 'Location approved: $locationName'
          : 'Location rejected: $locationName',
      'body': note ?? '',
      'route': '/map/proposals',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!approved) return;

    // Lightweight reputation award (mirrors mobile ReputationRepository).
    final day = DateTime.now();
    final dayKey =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final awardId =
        '${proposedBy}_locationApproved_loc_${locationName.hashCode}';
    final awardRef = _db.collection('reputation_awards').doc(awardId);
    final dailyRef =
        _db.collection('reputation_daily').doc('${proposedBy}_locationApproved_$dayKey');
    final userRef = _db.collection('users').doc(proposedBy);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(awardRef);
      if (existing.exists) return;
      final dailySnap = await tx.get(dailyRef);
      final used = (dailySnap.data()?['count'] as num?)?.toInt() ?? 0;
      if (used >= 5) return;
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;
      final current =
          (userSnap.data()?['reputationPoints'] as num?)?.toInt() ?? 0;
      final next = current + 25;
      final level = next >= 1000
          ? 'fieldExpert'
          : next >= 400
              ? 'trustedHunter'
              : next >= 100
                  ? 'activeHunter'
                  : 'beginner';
      tx.set(awardRef, {
        'targetUid': proposedBy,
        'actorUid': reviewerUid,
        'action': 'locationApproved',
        'points': 25,
        'dayKey': dayKey,
        'sourceId': 'loc_${locationName.hashCode}',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(dailyRef, {
        'targetUid': proposedBy,
        'action': 'locationApproved',
        'dayKey': dayKey,
        'count': used + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(userRef, {
        'reputationPoints': next,
        'reputationLevel': level,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final badgeId = '${proposedBy}_map_contributor';
    final badgeRef = _db.collection('user_badges').doc(badgeId);
    final badgeSnap = await badgeRef.get();
    if (!badgeSnap.exists) {
      await badgeRef.set({
        'userId': proposedBy,
        'badgeId': 'map_contributor',
        'badgeName': 'Map Contributor',
        'awardedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> watchOpenReports() {
    return _db
        .collection('moderation_reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Future<void> resolveReport({
    required String reportId,
    required String resolverUid,
    String resolution = 'resolved',
  }) async {
    await _db.collection('moderation_reports').doc(reportId).update({
      'status': resolution,
      'resolvedBy': resolverUid,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeletePost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveFieldReport(String reportId) async {
    await _db.collection('field_reports').doc(reportId).update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeListing(String listingId) async {
    await _db.collection('marketplace_listings').doc(listingId).update({
      'isRemoved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isDisabled': disabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchRecentPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchRecentFieldReports() {
    return _db
        .collection('field_reports')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchListings() {
    return _db
        .collection('marketplace_listings')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchBadges() {
    return _db.collection('badges').orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Future<void> upsertBadge({
    String? id,
    required String name,
    required String description,
    required String criteria,
    int pointsHint = 0,
  }) async {
    final ref = id == null
        ? _db.collection('badges').doc()
        : _db.collection('badges').doc(id);
    await ref.set({
      'name': name,
      'description': description,
      'criteria': criteria,
      'pointsHint': pointsHint,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteBadge(String id) async {
    await _db.collection('badges').doc(id).delete();
  }

  Future<Map<String, int>> loadAnalyticsCounts() async {
    Future<int> countOf(String collection, {String? field, Object? equals}) async {
      Query<Map<String, dynamic>> q = _db.collection(collection);
      if (field != null) {
        q = q.where(field, isEqualTo: equals);
      }
      final agg = await q.count().get();
      return agg.count ?? 0;
    }

    final results = await Future.wait([
      countOf('users'),
      countOf('posts', field: 'isDeleted', equals: false),
      countOf('field_reports'),
      countOf('hunting_locations', field: 'status', equals: 'pending'),
      countOf('hunting_locations', field: 'status', equals: 'approved'),
      countOf('moderation_reports', field: 'status', equals: 'open'),
      countOf('marketplace_listings', field: 'isRemoved', equals: false),
      countOf('conversations'),
    ]);

    return {
      'users': results[0],
      'posts': results[1],
      'fieldReports': results[2],
      'pendingLocations': results[3],
      'approvedLocations': results[4],
      'openReports': results[5],
      'listings': results[6],
      'conversations': results[7],
    };
  }
}

class AdminException implements Exception {
  AdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
