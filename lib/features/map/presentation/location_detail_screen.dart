import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/hunting_location.dart';
import '../../field_reports/presentation/widgets/field_report_card.dart';
import '../application/location_providers.dart';

class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({super.key, required this.locationId});

  final String locationId;

  Future<void> _openDirections(HuntingLocation loc) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(locationId));
    final reportsAsync = ref.watch(locationRelatedReportsProvider(locationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (loc) {
          if (loc == null) {
            return const Center(child: Text('Location not found.'));
          }
          return Container(
            decoration: const BoxDecoration(gradient: AppColors.dawnWash),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(loc.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  '${loc.region}, ${loc.country}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(status: loc.status),
                    ...loc.tags.map(
                      (t) => Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                if (loc.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(loc.description),
                ],
                if (loc.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: loc.photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: loc.photoUrls[i],
                            width: 240,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _openDirections(loc),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Open directions'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Related field reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                reportsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('$e'),
                  data: (reports) {
                    if (reports.isEmpty) {
                      return Text(
                        'No linked reports yet. File a report with this location id.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.clay,
                            ),
                      );
                    }
                    return Column(
                      children: [
                        for (final r in reports) ...[
                          FieldReportCard(report: r, compact: true),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final LocationStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      LocationStatus.pending => 'Pending review',
      LocationStatus.approved => 'Approved',
      LocationStatus.rejected => 'Rejected',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canopy.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
