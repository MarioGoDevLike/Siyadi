import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/hunting_location.dart';
import '../../../data/models/user_profile.dart';

class LocationRepository {
  LocationRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _locations =>
      _db.collection(FirestorePaths.huntingLocations);

  /// Lebanon demo spots used when Firestore has no approved locations yet.
  static List<HuntingLocation> demoApprovedLocations() {
    return const [
      HuntingLocation(
        id: 'demo_bekaa_west',
        name: 'West Bekaa foothills',
        country: 'Lebanon',
        region: 'Bekaa',
        latitude: 33.6472,
        longitude: 35.7415,
        proposedBy: 'seed',
        description: 'Demo approved spot for map testing (not in Firestore).',
        tags: ['demo', 'foothills'],
        status: LocationStatus.approved,
        visibility: LocationVisibility.community,
      ),
      HuntingLocation(
        id: 'demo_akkar_ridge',
        name: 'Akkar ridge overlook',
        country: 'Lebanon',
        region: 'Akkar',
        latitude: 34.5500,
        longitude: 36.0780,
        proposedBy: 'seed',
        description: 'Demo approved spot for map testing (not in Firestore).',
        tags: ['demo', 'ridge'],
        status: LocationStatus.approved,
        visibility: LocationVisibility.community,
      ),
      HuntingLocation(
        id: 'demo_chouf',
        name: 'Chouf highland trail',
        country: 'Lebanon',
        region: 'Mount Lebanon',
        latitude: 33.6950,
        longitude: 35.5800,
        proposedBy: 'seed',
        description: 'Demo approved spot for map testing (not in Firestore).',
        tags: ['demo', 'highland'],
        status: LocationStatus.approved,
        visibility: LocationVisibility.community,
      ),
    ];
  }

  Stream<List<HuntingLocation>> watchApprovedLocations({
    String country = 'Lebanon',
  }) {
    return _locations
        .where('status', isEqualTo: LocationStatus.approved.name)
        .where('country', isEqualTo: country)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(HuntingLocation.fromDoc)
          .where((l) => l.visibility == LocationVisibility.community)
          .toList();
    });
  }

  Stream<List<HuntingLocation>> watchMyProposals(String uid) {
    return _locations
        .where('proposedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(HuntingLocation.fromDoc).toList());
  }

  Stream<HuntingLocation?> watchLocation(String id) {
    return _locations.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return HuntingLocation.fromDoc(snap);
    });
  }

  Future<HuntingLocation?> getLocation(String id) async {
    final snap = await _locations.doc(id).get();
    if (!snap.exists) return null;
    return HuntingLocation.fromDoc(snap);
  }

  Future<HuntingLocation> proposeLocation({
    required UserProfile proposer,
    required String name,
    required String description,
    required String region,
    required double latitude,
    required double longitude,
    required LocationVisibility visibility,
    List<String> tags = const [],
    List<File> imageFiles = const [],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw LocationException('Give this spot a name.');
    }
    if (region.trim().isEmpty) {
      throw LocationException('Choose a region.');
    }

    final id = _uuid.v4();
    final photoUrls = <String>[];
    for (var i = 0; i < imageFiles.length && i < 4; i++) {
      final ref = _storage.ref(
        StoragePaths.locationMedia(proposer.uid, id, 'image_$i.jpg'),
      );
      await ref.putFile(
        imageFiles[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrls.add(await ref.getDownloadURL());
    }

    final location = HuntingLocation(
      id: id,
      name: trimmed,
      description: description.trim(),
      country: proposer.country,
      region: region.trim(),
      latitude: latitude,
      longitude: longitude,
      proposedBy: proposer.uid,
      tags: tags,
      photoUrls: photoUrls,
      status: LocationStatus.pending,
      visibility: visibility,
    );

    await _locations.doc(id).set(location.toMap(forCreate: true));
    return location;
  }

  /// Admin-only: writes a few approved Lebanon spots for map testing.
  Future<int> seedApprovedDemoLocations({
    required String adminUid,
  }) async {
    final existing = await _locations
        .where('status', isEqualTo: LocationStatus.approved.name)
        .where('country', isEqualTo: 'Lebanon')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return 0;

    final seeds = [
      (
        'West Bekaa foothills',
        'Bekaa',
        33.6472,
        35.7415,
        'Community foothills access — seed data for map QA.',
        ['foothills', 'seed'],
      ),
      (
        'Akkar ridge overlook',
        'Akkar',
        34.5500,
        36.0780,
        'Ridge overlook seed location for map QA.',
        ['ridge', 'seed'],
      ),
      (
        'Chouf highland trail',
        'Mount Lebanon',
        33.6950,
        35.5800,
        'Highland trail seed location for map QA.',
        ['highland', 'seed'],
      ),
    ];

    var written = 0;
    for (final s in seeds) {
      final id = _uuid.v4();
      final location = HuntingLocation(
        id: id,
        name: s.$1,
        country: 'Lebanon',
        region: s.$2,
        latitude: s.$3,
        longitude: s.$4,
        proposedBy: adminUid,
        description: s.$5,
        tags: s.$6,
        status: LocationStatus.approved,
        visibility: LocationVisibility.community,
      );
      await _locations.doc(id).set(location.toMap(forCreate: true));
      written++;
    }
    return written;
  }
}

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
