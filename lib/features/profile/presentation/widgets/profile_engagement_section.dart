import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reputation/application/engagement_providers.dart';

class ProfileEngagementSection extends ConsumerWidget {
  const ProfileEngagementSection({
    super.key,
    required this.uid,
    required this.isOwn,
  });

  final String uid;
  final bool isOwn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(userBadgesProvider(uid)).asData?.value ?? const [];
    final progress = isOwn
        ? ref.watch(weeklyChallengeProgressProvider).asData?.value ?? 0
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badges', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          Text(
            'No badges yet — file field reports and contribute map spots.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.clay,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in badges)
                Chip(
                  avatar: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 18,
                    color: AppColors.brass,
                  ),
                  label: Text(badge.badgeName),
                  side: const BorderSide(color: AppColors.mistDeep),
                  backgroundColor: AppColors.snow.withValues(alpha: 0.8),
                ),
            ],
          ),
        if (progress != null) ...[
          const SizedBox(height: 20),
          Text(
            'Weekly challenge',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.snow.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field Scout — file 3 reports today',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (progress.clamp(0, 3)) / 3,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.mistDeep,
                  color: AppColors.canopy,
                ),
                const SizedBox(height: 6),
                Text(
                  '$progress / 3 reports today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
