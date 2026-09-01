import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/post.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../reputation/application/engagement_providers.dart';
import '../../application/post_providers.dart';
import '../../data/post_repository.dart';
import 'post_media_carousel.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  Future<void> _toggleLike(WidgetRef ref, BuildContext context) async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final uid = profile?.uid ?? ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    try {
      final liked = await ref.read(postRepositoryProvider).toggleLike(
            postId: post.id,
            uid: uid,
          );
      if (liked) {
        await ref.read(engagementFanoutProvider).onPostLiked(
              actorUid: uid,
              authorId: post.authorId,
              postId: post.id,
              actorName: profile?.displayName ?? 'Someone',
            );
      }
    } on PostRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _toggleSave(WidgetRef ref, BuildContext context) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    try {
      await ref.read(postRepositoryProvider).toggleSave(
            postId: post.id,
            uid: uid,
          );
    } on PostRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _report(WidgetRef ref, BuildContext context) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    await ref.read(postRepositoryProvider).reportContent(
          reporterId: uid,
          targetType: 'post',
          targetId: post.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — we received your report.')),
      );
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext context) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This removes the post from the community feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(postRepositoryProvider).softDeletePost(
            postId: post.id,
            authorId: uid,
          );
    } on PostRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  String _timeLabel(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(postLikedProvider(post.id)).asData?.value ?? false;
    final saved = ref.watch(postSavedProvider(post.id)).asData?.value ?? false;
    final myUid = ref.watch(authUserProvider).asData?.value?.uid;
    final isOwn = myUid == post.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.snow.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mistDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    context.push(AppRoutes.userProfile(post.authorId)),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
                  backgroundImage: post.authorPhotoUrl != null
                      ? CachedNetworkImageProvider(post.authorPhotoUrl!)
                      : null,
                  child: post.authorPhotoUrl == null
                      ? Text(
                          post.authorDisplayName.isNotEmpty
                              ? post.authorDisplayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.canopy),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.push(AppRoutes.userProfile(post.authorId)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorDisplayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${post.authorUsername} · ${_timeLabel(post.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.clay,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') _report(ref, context);
                  if (value == 'delete') _delete(ref, context);
                },
                itemBuilder: (context) => [
                  if (isOwn)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete post'),
                    ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report'),
                  ),
                ],
              ),
            ],
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.caption, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            PostMediaCarousel(
              mediaUrls: post.mediaUrls,
              mediaType: post.mediaType,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () => _toggleLike(ref, context),
                icon: Icon(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: liked ? AppColors.danger : AppColors.clay,
                ),
              ),
              Text('${post.likeCount}'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.push(AppRoutes.postComments(post.id)),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                color: AppColors.clay,
              ),
              Text('${post.commentCount}'),
              const Spacer(),
              IconButton(
                onPressed: () => _toggleSave(ref, context),
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: saved ? AppColors.canopy : AppColors.clay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
