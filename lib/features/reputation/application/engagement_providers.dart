import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/engagement.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/engagement_repositories.dart';
import 'engagement_fanout.dart';

final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  return ReputationRepository(firestore: ref.watch(firestoreProvider));
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(firestore: ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: ref.watch(firestoreProvider));
});

final userBadgesProvider =
    StreamProvider.family<List<UserBadge>, String>((ref, uid) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);
  return ref.watch(badgeRepositoryProvider).watchUserBadges(uid);
});

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(const []);
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchForUser(uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(myNotificationsProvider).asData?.value ?? const [];
  return list.where((n) => !n.read).length;
});

final weeklyChallengeProgressProvider = FutureProvider<int>((ref) async {
  if (Firebase.apps.isEmpty) return 0;
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null) return 0;
  return ref.watch(badgeRepositoryProvider).countFieldReportsToday(uid);
});

final engagementFanoutProvider = Provider<EngagementFanout>((ref) {
  return EngagementFanout(
    reputation: ref.watch(reputationRepositoryProvider),
    notifications: ref.watch(notificationRepositoryProvider),
    badges: ref.watch(badgeRepositoryProvider),
  );
});
