import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(firestore: ref.watch(firestoreProvider));
});

final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchProfile(uid);
});

final isFollowingProvider =
    StreamProvider.family<bool, String>((ref, targetUid) {
  final me = ref.watch(authUserProvider).asData?.value;
  if (me == null || me.uid == targetUid) {
    return Stream<bool>.value(false);
  }
  return ref.watch(followRepositoryProvider).watchIsFollowing(
        followerId: me.uid,
        followingId: targetUid,
      );
});

final followerIdsProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  return ref.watch(followRepositoryProvider).watchFollowerIds(uid);
});

final followingIdsProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  return ref.watch(followRepositoryProvider).watchFollowingIds(uid);
});

final followListProfilesProvider =
    FutureProvider.family<List<UserProfile>, List<String>>((ref, uids) async {
  return ref.watch(followRepositoryProvider).loadProfiles(uids);
});
