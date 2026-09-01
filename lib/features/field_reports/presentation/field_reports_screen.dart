import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../application/field_report_providers.dart';
import 'widgets/field_report_card.dart';

class FieldReportsScreen extends ConsumerWidget {
  const FieldReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportsFilterProvider);
    final reportsAsync = ref.watch(filteredFieldReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Field reports')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  SegmentedButton<ReportsListScope>(
                    segments: const [
                      ButtonSegment(
                        value: ReportsListScope.today,
                        label: Text('Today'),
                      ),
                      ButtonSegment(
                        value: ReportsListScope.archive,
                        label: Text('Archive'),
                      ),
                      ButtonSegment(
                        value: ReportsListScope.all,
                        label: Text('All'),
                      ),
                    ],
                    selected: {filter.scope},
                    onSelectionChanged: (value) {
                      ref
                          .read(reportsFilterProvider.notifier)
                          .setScope(value.first);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(filter.region ?? 'all'),
                    initialValue: filter.region,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All regions'),
                      ),
                      ...AppConstants.lebanonRegions.map(
                        (r) => DropdownMenuItem(value: r, child: Text(r)),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(reportsFilterProvider.notifier).setRegion(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter by area',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref
                          .read(reportsFilterProvider.notifier)
                          .setAreaQuery(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: reportsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e', textAlign: TextAlign.center),
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return Center(
                      child: Text(
                        'No reports match these filters.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.clay,
                            ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return FieldReportCard(report: reports[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
