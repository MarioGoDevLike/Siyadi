import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_placeholder.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/application/auth_providers.dart';
import '../../messaging/application/messaging_providers.dart';
import '../../messaging/presentation/chat_screen.dart';
import '../../reputation/application/engagement_providers.dart';
import '../application/profile_providers.dart';
import 'widgets/follow_button.dart';
import 'widgets/profile_engagement_section.dart';
import 'widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authUserProvider).asData?.value;
    if (me == null) {
      return const FeaturePlaceholder(
        title: 'Profile',
        subtitle: 'Sign in to see your hunter profile.',
        icon: Icons.person_outline_rounded,
      );
    }
    return UserProfileView(uid: me.uid, isTabRoot: true);
  }
}

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserProfileView(uid: uid, isTabRoot: false);
  }
}

class UserProfileView extends ConsumerWidget {
  const UserProfileView({
    super.key,
    required this.uid,
    required this.isTabRoot,
  });

  final String uid;
  final bool isTabRoot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final myUid = ref.watch(authUserProvider).asData?.value?.uid;
    final isOwn = myUid != null && myUid == uid;

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: isTabRoot ? null : AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: isTabRoot ? null : AppBar(),
        body: FeaturePlaceholder(
          title: 'Profile',
          subtitle: 'Could not load profile: $error',
          icon: Icons.error_outline,
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: isTabRoot ? null : AppBar(),
            body: const FeaturePlaceholder(
              title: 'Profile',
              subtitle: 'This hunter has not finished onboarding yet.',
              icon: Icons.person_off_outlined,
            ),
          );
        }

        return Scaffold(
          appBar: isTabRoot
              ? null
              : AppBar(
                  title: Text('@${profile.username}'),
                ),
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.dawnWash),
            child: SafeArea(
              bottom: isTabRoot,
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, isTabRoot ? 16 : 8, 24, 100),
                children: [
                  if (isTabRoot) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Profile',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        _NotificationsEntryButton(),
                        const SizedBox(width: 8),
                        _MessagesEntryButton(),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ProfileHeader(
                    profile: profile,
                    onFollowersTap: () => context.push(
                      AppRoutes.userFollowers(profile.uid),
                    ),
                    onFollowingTap: () => context.push(
                      AppRoutes.userFollowing(profile.uid),
                    ),
                    trailing: isOwn
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.push(AppRoutes.editProfile),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit profile'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.outlined(
                                tooltip: 'Sign out',
                                onPressed: () async {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .signOut();
                                },
                                icon: const Icon(Icons.logout_rounded),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: FollowButton(targetUid: profile.uid),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => openChatWithUser(
                                    context: context,
                                    ref: ref,
                                    otherUid: profile.uid,
                                  ),
                                  icon: const Icon(Icons.mail_outline_rounded),
                                  label: const Text('Message'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  ProfileEngagementSection(uid: profile.uid, isOwn: isOwn),
                  const SizedBox(height: 28),
                  const ProfilePostsPlaceholder(),
                  if (isOwn) ...[
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: const Text('My location proposals'),
                      subtitle: const Text('Pending, approved, and rejected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(AppRoutes.myLocationProposals),
                    ),
                    const SizedBox(height: 12),
                    _DiscoverHint(currentUid: profile.uid),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsEntryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton.outlined(
      tooltip: 'Notifications',
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _MessagesEntryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider).asData?.value ?? const [];
    final myUid = ref.watch(authUserProvider).asData?.value?.uid;
    final unread = myUid == null
        ? 0
        : inbox.fold<int>(0, (sum, c) => sum + c.unreadFor(myUid));

    return IconButton.outlined(
      tooltip: 'Messages',
      onPressed: () => context.push(AppRoutes.messages),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.forum_outlined),
      ),
    );
  }
}

class _DiscoverHint extends ConsumerWidget {
  const _DiscoverHint({required this.currentUid});

  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canopy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.canopy.withValues(alpha: 0.12)),
      ),
      child: Text(
        'Tap a hunter on the feed, then Message to start a private chat. '
        'Your inbox is in the messages icon above.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.canopySoft,
            ),
      ),
    );
  }
}

/// Public helper for navigating to a user profile from feed/cards later.
void openUserProfile(BuildContext context, UserProfile profile) {
  context.push(AppRoutes.userProfile(profile.uid));
}
