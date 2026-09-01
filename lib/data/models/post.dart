import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.country,
    required this.region,
    this.caption = '',
    this.mediaUrls = const [],
    this.mediaType = PostMediaType.none,
    this.likeCount = 0,
    this.commentCount = 0,
    this.authorPhotoUrl,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String country;
  final String region;
  final String caption;
  final List<String> mediaUrls;
  final PostMediaType mediaType;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Post.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Post.fromMap(Map<String, dynamic> map, {required String id}) {
    return Post(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? '',
      authorDisplayName: map['authorDisplayName'] as String? ?? '',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
      country: map['country'] as String? ?? 'Lebanon',
      region: map['region'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      mediaUrls: (map['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mediaType: PostMediaType.fromWire(map['mediaType'] as String?),
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: _readTime(map['createdAt']),
      updatedAt: _readTime(map['updatedAt']),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorDisplayName': authorDisplayName,
      'authorPhotoUrl': authorPhotoUrl,
      'country': country,
      'region': region,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.name,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isDeleted': isDeleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}

enum PostMediaType {
  none,
  image,
  video,
  mixed;

  static PostMediaType fromWire(String? value) {
    return PostMediaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostMediaType.none,
    );
  }
}

DateTime? _readTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
