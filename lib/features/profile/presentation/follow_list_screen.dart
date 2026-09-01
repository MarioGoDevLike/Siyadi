import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../application/profile_providers.dart';

enum FollowListType { followers, following }

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.uid,
    required this.type,
  });

  final String uid;
  final FollowListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = type == FollowListType.followers
        ? ref.watch(followerIdsProvider(uid))
        : ref.watch(followingIdsProvider(uid));

    final title =
        type == FollowListType.followers ? 'Followers' : 'Following';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: idsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (ids) {
            if (ids.isEmpty) {
              return Center(
                child: Text(
                  type == FollowListType.followers
                      ? 'No followers yet.'
                      : 'Not following anyone yet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.clay,
                      ),
                ),
              );
            }

            final profilesAsync = ref.watch(followListProfilesProvider(ids));
            return profilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (profiles) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _UserTile(profile: profile);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.snow.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutes.userProfile(profile.uid)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.mistDeep),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: AppColors.canopy),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '@${profile.username}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.clay,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.clay),
            ],
          ),
        ),
      ),
    );
  }
}
