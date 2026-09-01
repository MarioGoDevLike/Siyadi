import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/messaging_providers.dart';
import '../data/messaging_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  bool _markedRead = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (_markedRead) return;
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    _markedRead = true;
    try {
      await ref.read(messagingRepositoryProvider).markRead(
            conversationId: widget.conversationId,
            uid: uid,
          );
    } catch (_) {
      _markedRead = false;
    }
  }

  Future<void> _send() async {
    final uid = ref.read(authUserProvider).asData?.value?.uid;
    if (uid == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(messagingRepositoryProvider).sendMessage(
            conversationId: widget.conversationId,
            senderId: uid,
            text: text,
          );
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } on MessagingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync =
        ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final myUid = ref.watch(authUserProvider).asData?.value?.uid;

    ref.listen(chatMessagesProvider(widget.conversationId), (_, next) {
      if (next.hasValue) _markRead();
    });

    final title = conversationAsync.asData?.value != null && myUid != null
        ? conversationAsync.asData!.value!.otherDisplayName(myUid)
        : 'Chat';
    final otherUid = conversationAsync.asData?.value != null && myUid != null
        ? conversationAsync.asData!.value!.otherParticipantId(myUid)
        : null;
    final photo = conversationAsync.asData?.value != null && myUid != null
        ? conversationAsync.asData!.value!.otherPhotoUrl(myUid)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.canopy.withValues(alpha: 0.12),
              backgroundImage:
                  photo != null ? CachedNetworkImageProvider(photo) : null,
              child: photo == null
                  ? Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: otherUid == null
                    ? null
                    : () => context.push(AppRoutes.userProfile(otherUid)),
                child: Text(title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Send the first message.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.clay,
                            ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final mine = m.senderId == myUid;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.canopy
                                : AppColors.snow.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                            border: mine
                                ? null
                                : Border.all(color: AppColors.mistDeep),
                          ),
                          child: Text(
                            m.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: mine ? AppColors.fog : AppColors.bark,
                                ),
                          ),
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
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Message…',
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

/// Opens an existing 1:1 chat or creates one, then navigates.
Future<void> openChatWithUser({
  required BuildContext context,
  required WidgetRef ref,
  required String otherUid,
}) async {
  final me = ref.read(currentUserProfileProvider).asData?.value;
  if (me == null) return;

  try {
    final repo = ref.read(messagingRepositoryProvider);
    final other = await repo.loadUser(otherUid);
    if (other == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hunter profile not found.')),
        );
      }
      return;
    }

    final conversationId = await repo.openOrCreateConversation(
      me: me,
      other: other,
    );
    if (context.mounted) {
      context.push(AppRoutes.chat(conversationId));
    }
  } on MessagingException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
