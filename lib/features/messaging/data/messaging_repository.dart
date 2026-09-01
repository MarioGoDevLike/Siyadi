import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/user_profile.dart';

/// Hook for in-app notification fan-out after a message is written.
class MessagingNotificationHook {
  const MessagingNotificationHook({this.onSent});

  final Future<void> Function({
    required String conversationId,
    required String recipientId,
    required String senderId,
    required String preview,
  })? onSent;

  Future<void> onMessageSent({
    required String conversationId,
    required String recipientId,
    required String senderId,
    required String preview,
  }) async {
    final handler = onSent;
    if (handler == null) return;
    await handler(
      conversationId: conversationId,
      recipientId: recipientId,
      senderId: senderId,
      preview: preview,
    );
  }
}

class MessagingRepository {
  MessagingRepository({
    required FirebaseFirestore firestore,
    this.notificationHook = const MessagingNotificationHook(),
  }) : _db = firestore;

  final FirebaseFirestore _db;
  final MessagingNotificationHook notificationHook;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection(FirestorePaths.conversations);

  DocumentReference<Map<String, dynamic>> _conversationRef(String id) =>
      _conversations.doc(id);

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversationRef(conversationId).collection(FirestorePaths.messages);

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  Stream<List<Conversation>> watchInbox(String uid) {
    return _conversations
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(Conversation.fromDoc).toList());
  }

  Stream<Conversation?> watchConversation(String conversationId) {
    return _conversationRef(conversationId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Conversation.fromDoc(snap);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _messages(conversationId)
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromDoc(d, conversationId: conversationId))
              .toList(),
        );
  }

  /// Ensures a 1:1 conversation exists and returns its id.
  Future<String> openOrCreateConversation({
    required UserProfile me,
    required UserProfile other,
  }) async {
    if (me.uid == other.uid) {
      throw MessagingException('You cannot message yourself.');
    }

    if (!other.privacy.allowMessagesFromAnyone) {
      final iFollowThem = await _db
          .collection(FirestorePaths.follows)
          .doc('${me.uid}_${other.uid}')
          .get();
      final theyFollowMe = await _db
          .collection(FirestorePaths.follows)
          .doc('${other.uid}_${me.uid}')
          .get();
      if (!iFollowThem.exists && !theyFollowMe.exists) {
        throw MessagingException(
          'This hunter only accepts messages from people in their network.',
        );
      }
    }

    final id = Conversation.idFor(me.uid, other.uid);
    final ref = _conversationRef(id);
    final snap = await ref.get();
    if (snap.exists) return id;

    final sorted = [me.uid, other.uid]..sort();
    await ref.set({
      'participantIds': sorted,
      'lastMessageText': '',
      'lastSenderId': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {
        me.uid: 0,
        other.uid: 0,
      },
      'participantNames': {
        me.uid: me.displayName,
        other.uid: other.displayName,
      },
      'participantUsernames': {
        me.uid: me.username,
        other.uid: other.username,
      },
      'participantPhotoUrls': {
        me.uid: me.photoUrl,
        other.uid: other.photoUrl,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw MessagingException('Message cannot be empty.');
    }

    final convRef = _conversationRef(conversationId);
    final messageRef = _messages(conversationId).doc();

    String? recipientId;

    await _db.runTransaction((tx) async {
      final convSnap = await tx.get(convRef);
      if (!convSnap.exists) {
        throw MessagingException('Conversation not found.');
      }
      final data = convSnap.data()!;
      final participants =
          (data['participantIds'] as List<dynamic>).map((e) => e.toString());
      if (!participants.contains(senderId)) {
        throw MessagingException('You are not in this conversation.');
      }

      recipientId = participants.firstWhere((id) => id != senderId);
      final unreadRaw =
          Map<String, dynamic>.from(data['unreadCounts'] as Map? ?? {});
      final recipientUnread =
          ((unreadRaw[recipientId] as num?)?.toInt() ?? 0) + 1;

      tx.set(messageRef, {
        'senderId': senderId,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(convRef, {
        'lastMessageText': trimmed,
        'lastSenderId': senderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts.$senderId': 0,
        'unreadCounts.$recipientId': recipientUnread,
      });
    });

    if (recipientId != null) {
      await notificationHook.onMessageSent(
        conversationId: conversationId,
        recipientId: recipientId!,
        senderId: senderId,
        preview: trimmed,
      );
    }
  }

  Future<void> markRead({
    required String conversationId,
    required String uid,
  }) async {
    final ref = _conversationRef(conversationId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final participants =
        (snap.data()?['participantIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
    if (!participants.contains(uid)) return;

    await ref.update({
      'unreadCounts.$uid': 0,
    });
  }

  Future<UserProfile?> loadUser(String uid) async {
    final snap = await _userRef(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromDoc(snap);
  }
}

class MessagingException implements Exception {
  MessagingException(this.message);
  final String message;

  @override
  String toString() => message;
}
