import 'package:cloud_firestore/cloud_firestore.dart';

enum LocationStatus {
  pending,
  approved,
  rejected;

  static LocationStatus fromWire(String? value) {
    return LocationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationStatus.pending,
    );
  }
}

class HuntingLocation {
  const HuntingLocation({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.proposedBy,
    this.description = '',
    this.tags = const [],
    this.photoUrls = const [],
    this.status = LocationStatus.pending,
    this.visibility = LocationVisibility.community,
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String country;
  final String region;
  final double latitude;
  final double longitude;
  final String proposedBy;
  final List<String> tags;
  final List<String> photoUrls;
  final LocationStatus status;
  final LocationVisibility visibility;
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublic => status == LocationStatus.approved;

  factory HuntingLocation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return HuntingLocation.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory HuntingLocation.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final geo = map['geo'];
    double lat = (map['latitude'] as num?)?.toDouble() ?? 0;
    double lng = (map['longitude'] as num?)?.toDouble() ?? 0;
    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    }

    return HuntingLocation(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      country: map['country'] as String? ?? 'Lebanon',
      region: map['region'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      proposedBy: map['proposedBy'] as String? ?? '',
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
      photoUrls: (map['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: LocationStatus.fromWire(map['status'] as String?),
      visibility: LocationVisibility.fromWire(map['visibility'] as String?),
      reviewNote: map['reviewNote'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _readTime(map['reviewedAt']),
      createdAt: _readTime(map['createdAt']),
      updatedAt: _readTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'country': country,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'geo': GeoPoint(latitude, longitude),
      'proposedBy': proposedBy,
      'tags': tags,
      'photoUrls': photoUrls,
      'status': status.name,
      'visibility': visibility.name,
      'reviewNote': reviewNote,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}

enum LocationVisibility {
  /// Visible to community after approval.
  community,

  /// Kept private to proposer / limited audience until policy expands.
  private;

  static LocationVisibility fromWire(String? value) {
    return LocationVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationVisibility.community,
    );
  }
}

DateTime? _readTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
