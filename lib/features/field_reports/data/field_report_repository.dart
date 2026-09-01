import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/field_report.dart';
import '../../../data/models/user_profile.dart';

class FieldReportRepository {
  FieldReportRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection(FirestorePaths.fieldReports);

  static String dayKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Stream<List<FieldReport>> watchCountryReports({
    required String country,
    bool? archived,
    String? region,
    int limit = 60,
  }) {
    Query<Map<String, dynamic>> query = _reports.where(
      'country',
      isEqualTo: country,
    );

    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    } else if (archived != null) {
      query = query.where('isArchived', isEqualTo: archived);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      var list = snap.docs.map(FieldReport.fromDoc).toList();
      if (region != null && region.isNotEmpty && archived != null) {
        list = list.where((r) => r.isArchived == archived).toList();
      }
      return list;
    });
  }

  Stream<List<FieldReport>> watchTodaysReports({
    required String country,
    String? region,
  }) {
    return watchCountryReports(
      country: country,
      archived: false,
      region: region,
      limit: 40,
    ).map(
      (list) => list
          .where((r) => isSameCalendarDay(r.reportDate, DateTime.now()))
          .toList(),
    );
  }

  Future<FieldReport> createReport({
    required UserProfile author,
    required String area,
    required DateTime reportDate,
    required BirdActivityLevel birdActivity,
    String conditions = '',
    String weatherNotes = '',
    String? locationId,
    List<File> imageFiles = const [],
  }) async {
    final trimmedArea = area.trim();
    if (trimmedArea.isEmpty) {
      throw FieldReportException('Add an area name for this report.');
    }

    final reportId = _uuid.v4();
    final mediaUrls = <String>[];
    for (var i = 0; i < imageFiles.length && i < 4; i++) {
      final ref = _storage.ref(
        StoragePaths.fieldReportMedia(author.uid, reportId, 'image_$i.jpg'),
      );
      await ref.putFile(
        imageFiles[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      mediaUrls.add(await ref.getDownloadURL());
    }

    final normalizedDate = DateTime(
      reportDate.year,
      reportDate.month,
      reportDate.day,
    );
    final archived = !isSameCalendarDay(normalizedDate, DateTime.now());

    final report = FieldReport(
      id: reportId,
      authorId: author.uid,
      authorUsername: author.username,
      authorDisplayName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      country: author.country,
      region: author.region,
      area: trimmedArea,
      reportDate: normalizedDate,
      conditions: conditions.trim(),
      birdActivity: birdActivity,
      weatherNotes: weatherNotes.trim(),
      mediaUrls: mediaUrls,
      locationId: locationId?.trim().isEmpty == true ? null : locationId?.trim(),
      isArchived: archived,
    );

    await _reports.doc(reportId).set({
      ...report.toMap(forCreate: true),
      'reportDay': dayKey(normalizedDate),
    });
    return report;
  }
}

class FieldReportException implements Exception {
  FieldReportException(this.message);
  final String message;

  @override
  String toString() => message;
}
