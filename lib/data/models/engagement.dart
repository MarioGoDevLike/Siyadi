import 'package:cloud_firestore/cloud_firestore.dart';

enum ReputationAction {
  fieldReport(points: 10, dailyCap: 3),
  socialPost(points: 3, dailyCap: 5),
  receivedLike(points: 1, dailyCap: 20),
  receivedComment(points: 2, dailyCap: 15),
  locationApproved(points: 25, dailyCap: 5);

  const ReputationAction({required this.points, required this.dailyCap});

  final int points;
  final int dailyCap;
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    this.pointsHint = 0,
  });

  final String id;
  final String name;
  final String description;
  final String criteria;
  final int pointsHint;

  factory BadgeDefinition.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return BadgeDefinition(
      id: doc.id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      criteria: map['criteria'] as String? ?? '',
      pointsHint: (map['pointsHint'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserBadge {
  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.badgeName,
    this.awardedAt,
  });

  final String id;
  final String userId;
  final String badgeId;
  final String badgeName;
  final DateTime? awardedAt;

  factory UserBadge.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return UserBadge(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      badgeId: map['badgeId'] as String? ?? '',
      badgeName: map['badgeName'] as String? ?? '',
      awardedAt: map['awardedAt'] is Timestamp
          ? (map['awardedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body = '',
    this.route,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? route;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'generic',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      route: map['route'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.tempC,
    required this.feelsLikeC,
    required this.windSpeedMs,
    required this.windDirectionDeg,
    required this.description,
    required this.humidity,
    required this.placeName,
    this.isFallback = false,
  });

  final double tempC;
  final double feelsLikeC;
  final double windSpeedMs;
  final int windDirectionDeg;
  final String description;
  final int humidity;
  final String placeName;
  final bool isFallback;

  String get windDirectionLabel {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = ((windDirectionDeg % 360) / 45).round() % 8;
    return dirs[i];
  }

  String get compactLine =>
      '${tempC.round()}°C · ${description[0].toUpperCase()}${description.substring(1)} · wind ${windSpeedMs.toStringAsFixed(1)} m/s $windDirectionLabel';
}
