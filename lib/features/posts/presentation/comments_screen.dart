import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../reputation/application/engagement_providers.dart';
import '../application/post_providers.dart';
import '../data/post_repository.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    if (profile == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(postRepositoryProvider);
      await repo.addComment(
        postId: widget.postId,
        author: profile,
        text: text,
      );
      final authorId = await repo.getAuthorId(widget.postId);
      if (authorId != null) {
        await ref.read(engagementFanoutProvider).onCommentAdded(
              actorUid: profile.uid,
              authorId: authorId,
              postId: widget.postId,
              actorName: profile.displayName,
            );
      }
      _controller.clear();
    } on PostRepositoryException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    try {
      await ref.read(postRepositoryProvider).softDeleteComment(
            postId: widget.postId,
            commentId: commentId,
            authorId: uid,
          );
    } on PostRepositoryException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _reportComment(String commentId) async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    await ref.read(postRepositoryProvider).reportContent(
          reporterId: uid,
          targetType: 'comment',
          targetId: '${widget.postId}_$commentId',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment reported.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final myUid = ref.watch(authUserProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: Column(
          children: [
            Expanded(
              child: commentsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'Be the first to comment.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.clay,
                            ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final isOwn = myUid == c.authorId;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.snow.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.mistDeep),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => context.push(
                                AppRoutes.userProfile(c.authorId),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.canopy.withValues(alpha: 0.12),
                                backgroundImage: c.authorPhotoUrl != null
                                    ? CachedNetworkImageProvider(
                                        c.authorPhotoUrl!,
                                      )
                                    : null,
                                child: c.authorPhotoUrl == null
                                    ? Text(
                                        c.authorDisplayName.isNotEmpty
                                            ? c.authorDisplayName[0]
                                                .toUpperCase()
                                            : '?',
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.authorDisplayName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(c.text),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteComment(c.id);
                                }
                                if (value == 'report') {
                                  _reportComment(c.id);
                                }
                              },
                              itemBuilder: (context) => [
                                if (isOwn)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _busy ? null : _send(),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
