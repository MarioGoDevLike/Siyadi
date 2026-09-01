import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/field_report.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/field_report_repository.dart';

final fieldReportRepositoryProvider = Provider<FieldReportRepository>((ref) {
  return FieldReportRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

enum ReportsListScope { today, archive, all }

class ReportsFilter {
  const ReportsFilter({
    this.scope = ReportsListScope.today,
    this.region,
    this.areaQuery = '',
  });

  final ReportsListScope scope;
  final String? region;
  final String areaQuery;

  ReportsFilter copyWith({
    ReportsListScope? scope,
    String? region,
    bool clearRegion = false,
    String? areaQuery,
  }) {
    return ReportsFilter(
      scope: scope ?? this.scope,
      region: clearRegion ? null : (region ?? this.region),
      areaQuery: areaQuery ?? this.areaQuery,
    );
  }
}

class ReportsFilterNotifier extends Notifier<ReportsFilter> {
  @override
  ReportsFilter build() => const ReportsFilter();

  void setScope(ReportsListScope scope) =>
      state = state.copyWith(scope: scope);

  void setRegion(String? region) {
    if (region == null || region.isEmpty) {
      state = state.copyWith(clearRegion: true);
    } else {
      state = state.copyWith(region: region);
    }
  }

  void setAreaQuery(String query) =>
      state = state.copyWith(areaQuery: query);
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportsFilter>(
  ReportsFilterNotifier.new,
);

final todaysFieldReportsProvider = StreamProvider<List<FieldReport>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <FieldReport>[]);
  }
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final country = profile?.country ?? AppConstants.defaultCountry;
  return ref.watch(fieldReportRepositoryProvider).watchTodaysReports(
        country: country,
      );
});

final filteredFieldReportsProvider = StreamProvider<List<FieldReport>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <FieldReport>[]);
  }

  final filter = ref.watch(reportsFilterProvider);
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  final country = profile?.country ?? AppConstants.defaultCountry;
  final repo = ref.watch(fieldReportRepositoryProvider);

  final archived = switch (filter.scope) {
    ReportsListScope.today => false,
    ReportsListScope.archive => null,
    ReportsListScope.all => null,
  };

  return repo
      .watchCountryReports(
        country: country,
        archived: archived,
        region: filter.region,
      )
      .map((list) {
    final today = DateTime.now();
    var result = list;

    if (filter.scope == ReportsListScope.today) {
      result = result
          .where(
            (r) => FieldReportRepository.isSameCalendarDay(r.reportDate, today),
          )
          .toList();
    } else if (filter.scope == ReportsListScope.archive) {
      result = result
          .where(
            (r) =>
                r.isArchived ||
                !FieldReportRepository.isSameCalendarDay(r.reportDate, today),
          )
          .toList();
    }

    final q = filter.areaQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((r) => r.area.toLowerCase().contains(q))
          .toList();
    }
    return result;
  });
});
