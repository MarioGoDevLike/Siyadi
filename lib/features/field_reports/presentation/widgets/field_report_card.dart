import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/field_report.dart';

class FieldReportCard extends StatelessWidget {
  const FieldReportCard({
    super.key,
    required this.report,
    this.compact = false,
  });

  final FieldReport report;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.snow.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.userProfile(report.authorId)),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mistDeep),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 14 : 16,
                    backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
                    backgroundImage: report.authorPhotoUrl != null
                        ? CachedNetworkImageProvider(report.authorPhotoUrl!)
                        : null,
                    child: report.authorPhotoUrl == null
                        ? Text(
                            report.authorDisplayName.isNotEmpty
                                ? report.authorDisplayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.authorDisplayName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${report.area} · ${report.region}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.clay,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _ActivityChip(level: report.birdActivity),
                ],
              ),
              if (!compact) ...[
                if (report.conditions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    report.conditions,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (report.weatherNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    report.weatherNotes,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.clay,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (report.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: report.mediaUrls.first,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (report.locationId != null &&
                    report.locationId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Location ref: ${report.locationId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.canopySoft,
                        ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.level});

  final BirdActivityLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brass.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.bark,
            ),
      ),
    );
  }
}
