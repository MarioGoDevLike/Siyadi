import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminAuthUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(adminRepositoryProvider).watchAuth();
});

enum AdminGateStatus { loading, signedOut, notAdmin, ready }

final adminGateStatusProvider = Provider<AdminGateStatus>((ref) {
  final auth = ref.watch(adminAuthUserProvider);
  if (auth.isLoading) return AdminGateStatus.loading;
  if (auth.hasError) return AdminGateStatus.signedOut;
  final user = auth.asData?.value;
  if (user == null) return AdminGateStatus.signedOut;

  final adminAsync = ref.watch(adminFlagProvider(user.uid));
  if (adminAsync.isLoading) return AdminGateStatus.loading;
  if (adminAsync.asData?.value == true) return AdminGateStatus.ready;
  return AdminGateStatus.notAdmin;
});

final adminFlagProvider = StreamProvider.family<bool, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).watchIsAdmin(uid);
});

final pendingLocationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchPendingLocations();
});

final openReportsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchOpenReports();
});

final recentPostsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchRecentPosts();
});

final recentFieldReportsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchRecentFieldReports();
});

final listingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchListings();
});

final usersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers();
});

final badgesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).watchBadges();
});

final analyticsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(adminRepositoryProvider).loadAnalyticsCounts();
});
