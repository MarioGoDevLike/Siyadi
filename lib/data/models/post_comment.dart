import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.text,
    this.authorPhotoUrl,
    this.createdAt,
    this.isDeleted = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime? createdAt;
  final bool isDeleted;

  factory PostComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String postId,
  }) {
    final map = doc.data() ?? {};
    return PostComment(
      id: doc.id,
      postId: postId,
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? '',
      authorDisplayName: map['authorDisplayName'] as String? ?? '',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      text: map['text'] as String? ?? '',
      createdAt: _readTime(map['createdAt']),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'isDeleted': isDeleted,
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
