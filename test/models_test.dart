import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyadi/data/models/models.dart';
import 'package:siyadi/features/field_reports/data/field_report_repository.dart';

void main() {
  group('UserProfile', () {
    test('fromMap maps core identity and defaults reputation', () {
      final profile = UserProfile.fromMap(
        {
          'displayName': 'Mario',
          'username': 'MarioHunt',
          'usernameLower': 'mariohunt',
          'country': 'Lebanon',
          'region': 'Mount Lebanon',
          'onboardingComplete': true,
        },
        uid: 'uid-1',
      );

      expect(profile.uid, 'uid-1');
      expect(profile.usernameLower, 'mariohunt');
      expect(profile.reputationLevel, ReputationLevel.beginner);
      expect(profile.isAdmin, isFalse);
    });

    test('toMap forCreate includes server timestamps', () {
      const profile = UserProfile(
        uid: 'uid-1',
        displayName: 'Mario',
        username: 'mario',
        usernameLower: 'mario',
        country: 'Lebanon',
        region: 'Beirut',
      );

      final map = profile.toMap(forCreate: true);
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
      expect(map['isAdmin'], isFalse);
    });
  });

  group('ReputationLevel', () {
    test('fromPoints uses progressive thresholds', () {
      expect(ReputationLevel.fromPoints(0), ReputationLevel.beginner);
      expect(ReputationLevel.fromPoints(100), ReputationLevel.activeHunter);
      expect(ReputationLevel.fromPoints(400), ReputationLevel.trustedHunter);
      expect(ReputationLevel.fromPoints(1000), ReputationLevel.fieldExpert);
    });
  });

  group('HuntingLocation', () {
    test('isPublic only when approved', () {
      const pending = HuntingLocation(
        id: '1',
        name: 'Bekaa Spot',
        country: 'Lebanon',
        region: 'Bekaa',
        latitude: 33.8,
        longitude: 35.9,
        proposedBy: 'uid',
      );
      expect(pending.isPublic, isFalse);
      expect(
        pending.copyWithStatus(LocationStatus.approved).isPublic,
        isTrue,
      );
    });
  });

  group('FieldReport', () {
    test('fromMap reads bird activity enum', () {
      final report = FieldReport.fromMap(
        {
          'authorId': 'u1',
          'authorUsername': 'hunter',
          'authorDisplayName': 'Hunter',
          'country': 'Lebanon',
          'region': 'North',
          'area': 'Akkar',
          'reportDate': Timestamp.fromDate(DateTime(2026, 9, 1)),
          'birdActivity': 'high',
        },
        id: 'r1',
      );
      expect(report.birdActivity, BirdActivityLevel.high);
      expect(report.area, 'Akkar');
    });
  });

  group('FieldReportRepository helpers', () {
    test('dayKey formats calendar day as yyyy-MM-dd', () {
      expect(
        FieldReportRepository.dayKey(DateTime(2026, 9, 1)),
        '2026-09-01',
      );
    });

    test('isSameCalendarDay compares local y/m/d', () {
      expect(
        FieldReportRepository.isSameCalendarDay(
          DateTime(2026, 9, 1, 8),
          DateTime(2026, 9, 1, 22),
        ),
        isTrue,
      );
      expect(
        FieldReportRepository.isSameCalendarDay(
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 2),
        ),
        isFalse,
      );
    });
  });

  group('Conversation', () {
    test('idFor is stable regardless of uid order', () {
      expect(Conversation.idFor('b', 'a'), 'a_b');
      expect(Conversation.idFor('a', 'b'), 'a_b');
    });

    test('otherParticipantId and unreadFor resolve peer fields', () {
      const c = Conversation(
        id: 'a_b',
        participantIds: ['a', 'b'],
        unreadCounts: {'a': 2, 'b': 0},
        participantNames: {'a': 'Ada', 'b': 'Ben'},
      );
      expect(c.otherParticipantId('a'), 'b');
      expect(c.otherDisplayName('a'), 'Ben');
      expect(c.unreadFor('a'), 2);
    });
  });
}

extension on HuntingLocation {
  HuntingLocation copyWithStatus(LocationStatus status) {
    return HuntingLocation(
      id: id,
      name: name,
      country: country,
      region: region,
      latitude: latitude,
      longitude: longitude,
      proposedBy: proposedBy,
      description: description,
      tags: tags,
      photoUrls: photoUrls,
      status: status,
      visibility: visibility,
      reviewNote: reviewNote,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
