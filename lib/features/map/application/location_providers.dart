import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/field_report.dart';
import '../../../data/models/hunting_location.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../field_reports/application/field_report_providers.dart';
import '../data/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final approvedLocationsProvider =
    StreamProvider<List<HuntingLocation>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(LocationRepository.demoApprovedLocations());
  }
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final country = profile?.country ?? AppConstants.defaultCountry;
  return ref.watch(locationRepositoryProvider).watchApprovedLocations(
        country: country,
      );
});

/// Approved Firestore spots, or local demo markers when the map is empty.
final mapLocationsProvider = Provider<AsyncValue<List<HuntingLocation>>>((ref) {
  final async = ref.watch(approvedLocationsProvider);
  return async.when(
    data: (list) {
      if (list.isEmpty) {
        return AsyncValue.data(LocationRepository.demoApprovedLocations());
      }
      return AsyncValue.data(list);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.data(
      LocationRepository.demoApprovedLocations(),
    ),
  );
});

final myLocationProposalsProvider =
    StreamProvider<List<HuntingLocation>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <HuntingLocation>[]);
  }
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const <HuntingLocation>[]);
  return ref.watch(locationRepositoryProvider).watchMyProposals(uid);
});

final locationDetailProvider =
    StreamProvider.family<HuntingLocation?, String>((ref, id) {
  if (Firebase.apps.isEmpty) {
    final demo = LocationRepository.demoApprovedLocations()
        .where((l) => l.id == id)
        .firstOrNull;
    return Stream.value(demo);
  }
  if (id.startsWith('demo_')) {
    final demo = LocationRepository.demoApprovedLocations()
        .where((l) => l.id == id)
        .firstOrNull;
    return Stream.value(demo);
  }
  return ref.watch(locationRepositoryProvider).watchLocation(id);
});

final locationRelatedReportsProvider =
    StreamProvider.family<List<FieldReport>, String>((ref, locationId) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <FieldReport>[]);
  }
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final country = profile?.country ?? AppConstants.defaultCountry;
  return ref
      .watch(fieldReportRepositoryProvider)
      .watchCountryReports(country: country, limit: 40)
      .map(
        (list) => list
            .where((r) => r.locationId == locationId)
            .take(8)
            .toList(),
      );
});
