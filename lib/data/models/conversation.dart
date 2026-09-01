import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessageText = '',
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCounts = const {},
    this.participantNames = const {},
    this.participantUsernames = const {},
    this.participantPhotoUrls = const {},
    this.createdAt,
  });

  final String id;
  final List<String> participantIds;
  final String lastMessageText;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final Map<String, String> participantNames;
  final Map<String, String> participantUsernames;
  final Map<String, String?> participantPhotoUrls;
  final DateTime? createdAt;

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Conversation.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Conversation.fromMap(Map<String, dynamic> map, {required String id}) {
    final unreadRaw = map['unreadCounts'] as Map<String, dynamic>? ?? {};
    final namesRaw = map['participantNames'] as Map<String, dynamic>? ?? {};
    final usernamesRaw =
        map['participantUsernames'] as Map<String, dynamic>? ?? {};
    final photosRaw =
        map['participantPhotoUrls'] as Map<String, dynamic>? ?? {};

    return Conversation(
      id: id,
      participantIds: (map['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastMessageText: map['lastMessageText'] as String? ?? '',
      lastSenderId: map['lastSenderId'] as String?,
      lastMessageAt: _readTime(map['lastMessageAt']),
      unreadCounts: unreadRaw.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      participantNames: namesRaw.map((k, v) => MapEntry(k, v.toString())),
      participantUsernames:
          usernamesRaw.map((k, v) => MapEntry(k, v.toString())),
      participantPhotoUrls: photosRaw.map(
        (k, v) => MapEntry(k, v?.toString()),
      ),
      createdAt: _readTime(map['createdAt']),
    );
  }

  String otherParticipantId(String myUid) {
    return participantIds.firstWhere(
      (id) => id != myUid,
      orElse: () => myUid,
    );
  }

  String otherDisplayName(String myUid) {
    final other = otherParticipantId(myUid);
    return participantNames[other] ?? 'Hunter';
  }

  String otherUsername(String myUid) {
    final other = otherParticipantId(myUid);
    return participantUsernames[other] ?? '';
  }

  String? otherPhotoUrl(String myUid) {
    final other = otherParticipantId(myUid);
    return participantPhotoUrls[other];
  }

  int unreadFor(String myUid) => unreadCounts[myUid] ?? 0;

  /// Stable 1:1 conversation id from two user ids.
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String conversationId,
  }) {
    final map = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      conversationId: conversationId,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: _readTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'senderId': senderId,
      'text': text,
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}

DateTime? _readTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
