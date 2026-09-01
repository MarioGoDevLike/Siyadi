import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../reputation/application/engagement_providers.dart';
import '../../application/profile_providers.dart';
import '../../data/follow_repository.dart';

class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({super.key, required this.targetUid});

  final String targetUid;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    final me = ref.read(authUserProvider).asData?.value;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(followRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollow(followerId: me.uid, followingId: widget.targetUid);
      } else {
        await repo.follow(followerId: me.uid, followingId: widget.targetUid);
        final meProfile =
            ref.read(currentUserProfileProvider).asData?.value;
        await ref.read(engagementFanoutProvider).onFollowed(
              followerId: me.uid,
              followingId: widget.targetUid,
              followerName: meProfile?.displayName ?? 'Someone',
            );
      }
    } on FollowException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(isFollowingProvider(widget.targetUid));

    return followingAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) {
        if (isFollowing) {
          return OutlinedButton(
            onPressed: _busy ? null : () => _toggle(true),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Following'),
          );
        }
        return FilledButton(
          onPressed: _busy ? null : () => _toggle(false),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Follow'),
        );
      },
    );
  }
}
