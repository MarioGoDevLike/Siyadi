import 'package:cloud_firestore/cloud_firestore.dart';

enum BirdActivityLevel {
  none,
  low,
  moderate,
  high,
  excellent;

  String get label => switch (this) {
        BirdActivityLevel.none => 'None',
        BirdActivityLevel.low => 'Low',
        BirdActivityLevel.moderate => 'Moderate',
        BirdActivityLevel.high => 'High',
        BirdActivityLevel.excellent => 'Excellent',
      };

  static BirdActivityLevel fromWire(String? value) {
    return BirdActivityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BirdActivityLevel.moderate,
    );
  }
}

class FieldReport {
  const FieldReport({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.country,
    required this.region,
    required this.area,
    required this.reportDate,
    this.conditions = '',
    this.birdActivity = BirdActivityLevel.moderate,
    this.weatherNotes = '',
    this.mediaUrls = const [],
    this.locationId,
    this.authorPhotoUrl,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
  });

  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String country;
  final String region;
  final String area;
  final DateTime reportDate;
  final String conditions;
  final BirdActivityLevel birdActivity;
  final String weatherNotes;
  final List<String> mediaUrls;
  final String? locationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived;

  factory FieldReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return FieldReport.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory FieldReport.fromMap(Map<String, dynamic> map, {required String id}) {
    return FieldReport(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? '',
      authorDisplayName: map['authorDisplayName'] as String? ?? '',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      country: map['country'] as String? ?? 'Lebanon',
      region: map['region'] as String? ?? '',
      area: map['area'] as String? ?? '',
      reportDate: _readTime(map['reportDate']) ?? DateTime.now(),
      conditions: map['conditions'] as String? ?? '',
      birdActivity: BirdActivityLevel.fromWire(map['birdActivity'] as String?),
      weatherNotes: map['weatherNotes'] as String? ?? '',
      mediaUrls: (map['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      locationId: map['locationId'] as String?,
      createdAt: _readTime(map['createdAt']),
      updatedAt: _readTime(map['updatedAt']),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorPhotoUrl': authorPhotoUrl,
      'country': country,
      'region': region,
      'area': area,
      'reportDate': Timestamp.fromDate(reportDate),
      'conditions': conditions,
      'birdActivity': birdActivity.name,
      'weatherNotes': weatherNotes,
      'mediaUrls': mediaUrls,
      'locationId': locationId,
      'isArchived': isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}

DateTime? _readTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
