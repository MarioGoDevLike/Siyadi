import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post.dart';
import '../../../data/models/post_comment.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

enum FeedScope { local, explore }

class FeedScopeNotifier extends Notifier<FeedScope> {
  @override
  FeedScope build() => FeedScope.local;

  void setScope(FeedScope scope) => state = scope;
}

final feedScopeProvider =
    NotifierProvider<FeedScopeNotifier, FeedScope>(FeedScopeNotifier.new);

final feedPostsProvider = StreamProvider<List<Post>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <Post>[]);
  }

  final scope = ref.watch(feedScopeProvider);
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final repo = ref.watch(postRepositoryProvider);

  if (scope == FeedScope.explore) {
    return repo.watchExploreFeed();
  }

  final country = profile?.country ?? 'Lebanon';
  return repo.watchCountryFeed(country);
});

final postLikedProvider = StreamProvider.family<bool, String>((ref, postId) {
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null || Firebase.apps.isEmpty) return Stream.value(false);
  return ref.watch(postRepositoryProvider).watchIsLiked(postId: postId, uid: uid);
});

final postSavedProvider = StreamProvider.family<bool, String>((ref, postId) {
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null || Firebase.apps.isEmpty) return Stream.value(false);
  return ref.watch(postRepositoryProvider).watchIsSaved(postId: postId, uid: uid);
});

final postCommentsProvider =
    StreamProvider.family<List<PostComment>, String>((ref, postId) {
  if (Firebase.apps.isEmpty) return Stream.value(const <PostComment>[]);
  return ref.watch(postRepositoryProvider).watchComments(postId);
});
