import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.onFollowersTap,
    this.onFollowingTap,
    this.trailing,
  });

  final UserProfile profile;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : '?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.canopy,
                          ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '@${profile.username}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.clay,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.region}, ${profile.country}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(height: 16),
          trailing!,
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            _CountChip(
              label: 'Followers',
              count: profile.followersCount,
              onTap: onFollowersTap,
            ),
            const SizedBox(width: 12),
            _CountChip(
              label: 'Following',
              count: profile.followingCount,
              onTap: onFollowingTap,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.snow.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.mistDeep),
          ),
          child: Row(
            children: [
              const Icon(Icons.military_tech_outlined, color: AppColors.brass),
              const SizedBox(width: 10),
              Text(
                '${profile.reputationLevel.label} · ${profile.reputationPoints} pts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(profile.bio!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.snow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePostsPlaceholder extends StatelessWidget {
  const ProfilePostsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Posts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Your posts appear on the Home feed. Profile grid comes later.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.clay,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(
            3,
            (index) => Container(
              decoration: BoxDecoration(
                color: AppColors.canopy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mistDeep),
              ),
              child: const Icon(
                Icons.photo_outlined,
                color: AppColors.canopySoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
