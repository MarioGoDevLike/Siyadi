import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final pending = ref.watch(pendingLocationsProvider);
    final reports = ref.watch(openReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operations overview')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          analytics.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (counts) {
              final cards = [
                ('Users', counts['users'] ?? 0, Icons.people_outline, '/users'),
                ('Posts', counts['posts'] ?? 0, Icons.article_outlined, '/content'),
                (
                  'Pending locations',
                  counts['pendingLocations'] ?? 0,
                  Icons.place_outlined,
                  '/locations'
                ),
                (
                  'Approved locations',
                  counts['approvedLocations'] ?? 0,
                  Icons.check_circle_outline,
                  '/locations'
                ),
                (
                  'Open reports',
                  counts['openReports'] ?? 0,
                  Icons.flag_outlined,
                  '/moderation'
                ),
                (
                  'Listings',
                  counts['listings'] ?? 0,
                  Icons.storefront_outlined,
                  '/content'
                ),
                (
                  'Field reports',
                  counts['fieldReports'] ?? 0,
                  Icons.forest_outlined,
                  '/content'
                ),
                (
                  'Conversations',
                  counts['conversations'] ?? 0,
                  Icons.forum_outlined,
                  '/'
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in cards)
                    SizedBox(
                      width: 220,
                      child: Card(
                        child: InkWell(
                          onTap: () => context.go(c.$4),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(c.$3, color: AdminColors.brass),
                                const SizedBox(height: 12),
                                Text(
                                  '${c.$2}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                Text(c.$1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text('Needs attention', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          pending.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) => Text(
              '${list.length} location(s) awaiting review',
              style: TextStyle(
                color: list.isEmpty ? AdminColors.ok : AdminColors.brass,
              ),
            ),
          ),
          reports.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) => Text(
              '${list.length} open moderation report(s)',
              style: TextStyle(
                color: list.isEmpty ? AdminColors.ok : AdminColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tip: approve a pending location here and it appears on the mobile map immediately.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
