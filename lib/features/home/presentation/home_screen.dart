import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../field_reports/application/field_report_providers.dart';
import '../../field_reports/presentation/widgets/field_report_card.dart';
import '../../posts/application/post_providers.dart';
import '../../posts/presentation/widgets/post_card.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/home_weather_strip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedPostsProvider);
    final scope = ref.watch(feedScopeProvider);
    final todaysReports = ref.watch(todaysFieldReportsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(feedPostsProvider);
              ref.invalidate(todaysFieldReportsProvider);
              ref.invalidate(homeWeatherProvider);
              await Future.wait([
                ref.read(feedPostsProvider.future),
                ref.read(todaysFieldReportsProvider.future),
                ref.read(homeWeatherProvider.future),
              ]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppConstants.appTagline,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.clay,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        const HomeWeatherStrip(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              "Today's field reports",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.fieldReports),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        todaysReports.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (e, _) => Text(
                            'Could not load reports.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.clay),
                          ),
                          data: (reports) {
                            if (reports.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.snow.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.mistDeep),
                                ),
                                child: Text(
                                  'No reports filed today yet. Tap + → Field report.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.clay),
                                ),
                              );
                            }
                            final preview = reports.take(3).toList();
                            return Column(
                              children: [
                                for (final report in preview) ...[
                                  FieldReportCard(
                                    report: report,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Community feed',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            SegmentedButton<FeedScope>(
                              segments: const [
                                ButtonSegment(
                                  value: FeedScope.local,
                                  label: Text('Local'),
                                ),
                                ButtonSegment(
                                  value: FeedScope.explore,
                                  label: Text('Explore'),
                                ),
                              ],
                              selected: {scope},
                              onSelectionChanged: (value) {
                                ref
                                    .read(feedScopeProvider.notifier)
                                    .setScope(value.first);
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStatePropertyAll(
                                  Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                feedAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load feed.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_2_outlined,
                                size: 56,
                                color: AppColors.canopy.withValues(alpha: 0.28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No posts yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap + to share the first hunt moment.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.clay),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: posts[index]);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
