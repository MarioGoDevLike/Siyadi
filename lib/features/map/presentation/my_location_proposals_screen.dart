import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/hunting_location.dart';
import '../application/location_providers.dart';

class MyLocationProposalsScreen extends ConsumerWidget {
  const MyLocationProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myLocationProposalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My location proposals')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No proposals yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use Map → Propose, or Create → Propose location.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.clay,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            context.push(AppRoutes.proposeLocation),
                        child: const Text('Propose a spot'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final loc = list[index];
                return Material(
                  color: AppColors.snow.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () =>
                        context.push(AppRoutes.locationDetail(loc.id)),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mistDeep),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${loc.region} · ${loc.visibility.name}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.clay),
                                ),
                                if (loc.reviewNote != null &&
                                    loc.reviewNote!.isNotEmpty)
                                  Text(
                                    loc.reviewNote!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.danger),
                                  ),
                              ],
                            ),
                          ),
                          _StatusLabel(status: loc.status),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final LocationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LocationStatus.pending => ('Pending', AppColors.brass),
      LocationStatus.approved => ('Approved', AppColors.canopy),
      LocationStatus.rejected => ('Rejected', AppColors.danger),
    };
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}
