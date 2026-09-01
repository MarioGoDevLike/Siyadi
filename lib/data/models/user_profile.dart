import 'package:cloud_firestore/cloud_firestore.dart';

enum ReputationLevel {
  beginner,
  activeHunter,
  trustedHunter,
  fieldExpert;

  String get label => switch (this) {
        ReputationLevel.beginner => 'Beginner',
        ReputationLevel.activeHunter => 'Active Hunter',
        ReputationLevel.trustedHunter => 'Trusted Hunter',
        ReputationLevel.fieldExpert => 'Field Expert',
      };

  static ReputationLevel fromPoints(int points) {
    if (points >= 1000) return ReputationLevel.fieldExpert;
    if (points >= 400) return ReputationLevel.trustedHunter;
    if (points >= 100) return ReputationLevel.activeHunter;
    return ReputationLevel.beginner;
  }

  static ReputationLevel fromWire(String? value) {
    return ReputationLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReputationLevel.beginner,
    );
  }
}

class UserPrivacy {
  const UserPrivacy({
    this.showLocationSubmissions = true,
    this.allowMessagesFromAnyone = true,
    this.pushNotificationsEnabled = true,
  });

  final bool showLocationSubmissions;
  final bool allowMessagesFromAnyone;
  final bool pushNotificationsEnabled;

  factory UserPrivacy.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPrivacy();
    return UserPrivacy(
      showLocationSubmissions: map['showLocationSubmissions'] as bool? ?? true,
      allowMessagesFromAnyone: map['allowMessagesFromAnyone'] as bool? ?? true,
      pushNotificationsEnabled:
          map['pushNotificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'showLocationSubmissions': showLocationSubmissions,
        'allowMessagesFromAnyone': allowMessagesFromAnyone,
        'pushNotificationsEnabled': pushNotificationsEnabled,
      };

  UserPrivacy copyWith({
    bool? showLocationSubmissions,
    bool? allowMessagesFromAnyone,
    bool? pushNotificationsEnabled,
  }) {
    return UserPrivacy(
      showLocationSubmissions:
          showLocationSubmissions ?? this.showLocationSubmissions,
      allowMessagesFromAnyone:
          allowMessagesFromAnyone ?? this.allowMessagesFromAnyone,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.usernameLower,
    required this.country,
    required this.region,
    this.photoUrl,
    this.bio,
    this.reputationPoints = 0,
    this.reputationLevel = ReputationLevel.beginner,
    this.followersCount = 0,
    this.followingCount = 0,
    this.onboardingComplete = false,
    this.isAdmin = false,
    this.privacy = const UserPrivacy(),
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String username;
  final String usernameLower;
  final String country;
  final String region;
  final String? photoUrl;
  final String? bio;
  final int reputationPoints;
  final ReputationLevel reputationLevel;
  final int followersCount;
  final int followingCount;
  final bool onboardingComplete;
  final bool isAdmin;
  final UserPrivacy privacy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(data, uid: doc.id);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    return UserProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      username: map['username'] as String? ?? '',
      usernameLower: map['usernameLower'] as String? ??
          (map['username'] as String? ?? '').toLowerCase(),
      country: map['country'] as String? ?? 'Lebanon',
      region: map['region'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      reputationPoints: (map['reputationPoints'] as num?)?.toInt() ?? 0,
      reputationLevel: ReputationLevel.fromWire(map['reputationLevel'] as String?),
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      isAdmin: map['isAdmin'] as bool? ?? false,
      privacy: UserPrivacy.fromMap(map['privacy'] as Map<String, dynamic>?),
      createdAt: _readTime(map['createdAt']),
      updatedAt: _readTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'displayName': displayName,
      'username': username,
      'usernameLower': usernameLower,
      'country': country,
      'region': region,
      'photoUrl': photoUrl,
      'bio': bio,
      'reputationPoints': reputationPoints,
      'reputationLevel': reputationLevel.name,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'onboardingComplete': onboardingComplete,
      'isAdmin': isAdmin,
      'privacy': privacy.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? usernameLower,
    String? country,
    String? region,
    String? photoUrl,
    String? bio,
    int? reputationPoints,
    ReputationLevel? reputationLevel,
    int? followersCount,
    int? followingCount,
    bool? onboardingComplete,
    bool? isAdmin,
    UserPrivacy? privacy,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      country: country ?? this.country,
      region: region ?? this.region,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      reputationLevel: reputationLevel ?? this.reputationLevel,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      isAdmin: isAdmin ?? this.isAdmin,
      privacy: privacy ?? this.privacy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

DateTime? _readTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
