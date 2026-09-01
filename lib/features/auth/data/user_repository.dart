import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/user_profile.dart';

class UserRepository {
  UserRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection(FirestorePaths.users).doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _usernameRef(String usernameLower) {
    return _firestore.collection(FirestorePaths.usernames).doc(usernameLower);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userRef(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromDoc(snap);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _userRef(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromDoc(snap);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final lower = username.trim().toLowerCase();
    final snap = await _usernameRef(lower).get();
    return !snap.exists;
  }

  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref(StoragePaths.userAvatar(uid, 'avatar.jpg'));
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Reserves username + writes completed profile in one batch.
  Future<UserProfile> completeOnboarding({
    required String uid,
    required String displayName,
    required String username,
    required String country,
    required String region,
    String? photoUrl,
    String? bio,
  }) async {
    final usernameLower = username.trim().toLowerCase();
    final usernameDoc = await _usernameRef(usernameLower).get();
    if (usernameDoc.exists) {
      throw UserRepositoryException('That username is already taken.');
    }

    final profile = UserProfile(
      uid: uid,
      displayName: displayName.trim(),
      username: username.trim(),
      usernameLower: usernameLower,
      country: country,
      region: region,
      photoUrl: photoUrl,
      bio: bio?.trim().isEmpty == true ? null : bio?.trim(),
      onboardingComplete: true,
    );

    final batch = _firestore.batch();
    batch.set(_userRef(uid), profile.toMap(forCreate: true));
    batch.set(_usernameRef(usernameLower), {
      'uid': uid,
      'username': profile.username,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return profile;
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String country,
    required String region,
    String? bio,
    String? photoUrl,
    UserPrivacy? privacy,
  }) async {
    final data = <String, dynamic>{
      'displayName': displayName.trim(),
      'country': country,
      'region': region,
      'bio': bio?.trim().isEmpty == true ? null : bio?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    if (privacy != null) {
      data['privacy'] = privacy.toMap();
    }
    await _userRef(uid).update(data);
  }
}

class UserRepositoryException implements Exception {
  UserRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
