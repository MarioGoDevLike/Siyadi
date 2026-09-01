import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/services/firebase_providers.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(firebaseAuth: ref.watch(firebaseAuthProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

/// Firebase Auth user stream. Null when signed out.
final authUserProvider = StreamProvider<User?>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream<User?>.value(null);
  }
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Firestore profile for the signed-in user. Null if missing / signed out.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authUserProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream<UserProfile?>.value(null);
      return ref.watch(userRepositoryProvider).watchProfile(user.uid);
    },
    loading: () => Stream<UserProfile?>.value(null),
    error: (_, __) => Stream<UserProfile?>.value(null),
  );
});

enum AuthGateStatus {
  loading,
  signedOut,
  needsOnboarding,
  ready,
}

final authGateStatusProvider = Provider<AuthGateStatus>((ref) {
  if (Firebase.apps.isEmpty) {
    // Widget tests / no Firebase — treat as ready so shell screens render.
    return AuthGateStatus.ready;
  }

  final auth = ref.watch(authUserProvider);
  final profile = ref.watch(currentUserProfileProvider);

  if (auth.isLoading || (auth.hasValue && auth.value != null && profile.isLoading)) {
    return AuthGateStatus.loading;
  }

  if (auth.hasError) return AuthGateStatus.signedOut;

  final user = auth.asData?.value;
  if (user == null) return AuthGateStatus.signedOut;

  final userProfile = profile.asData?.value;
  if (userProfile == null || !userProfile.onboardingComplete) {
    return AuthGateStatus.needsOnboarding;
  }

  return AuthGateStatus.ready;
});
