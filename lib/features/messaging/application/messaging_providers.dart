import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/conversation.dart';
import '../../../data/services/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../reputation/application/engagement_providers.dart';
import '../data/messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final fanout = ref.watch(engagementFanoutProvider);
  return MessagingRepository(
    firestore: ref.watch(firestoreProvider),
    notificationHook: MessagingNotificationHook(
      onSent: ({
        required conversationId,
        required recipientId,
        required senderId,
        required preview,
      }) {
        final me = ref.read(currentUserProfileProvider).asData?.value;
        return fanout.onMessageSent(
          conversationId: conversationId,
          recipientId: recipientId,
          senderId: senderId,
          preview: preview,
          senderName: me?.displayName ?? 'Someone',
        );
      },
    ),
  );
});

final inboxProvider = StreamProvider<List<Conversation>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <Conversation>[]);
  }
  final uid = ref.watch(authUserProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const <Conversation>[]);
  return ref.watch(messagingRepositoryProvider).watchInbox(uid);
});

final conversationProvider =
    StreamProvider.family<Conversation?, String>((ref, conversationId) {
  if (Firebase.apps.isEmpty) return Stream.value(null);
  return ref
      .watch(messagingRepositoryProvider)
      .watchConversation(conversationId);
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const <ChatMessage>[]);
  }
  return ref.watch(messagingRepositoryProvider).watchMessages(conversationId);
});
