import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/post.dart';
import '../../../data/models/post_comment.dart';
import '../../../data/models/user_profile.dart';

class PostRepository {
  PostRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection(FirestorePaths.posts);

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _posts.doc(postId);

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _postRef(postId).collection(FirestorePaths.comments);

  DocumentReference<Map<String, dynamic>> _likeRef(String postId, String uid) =>
      _postRef(postId).collection('likes').doc(uid);

  DocumentReference<Map<String, dynamic>> _saveRef(String postId, String uid) =>
      _postRef(postId).collection('saves').doc(uid);

  Stream<List<Post>> watchCountryFeed(String country, {int limit = 40}) {
    return _posts
        .where('country', isEqualTo: country)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Post.fromDoc).toList());
  }

  Stream<List<Post>> watchExploreFeed({int limit = 40}) {
    return _posts
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Post.fromDoc).toList());
  }

  Stream<bool> watchIsLiked({required String postId, required String uid}) {
    return _likeRef(postId, uid).snapshots().map((s) => s.exists);
  }

  Stream<bool> watchIsSaved({required String postId, required String uid}) {
    return _saveRef(postId, uid).snapshots().map((s) => s.exists);
  }

  Stream<List<PostComment>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PostComment.fromDoc(d, postId: postId))
              .where((c) => !c.isDeleted)
              .toList(),
        );
  }

  Future<Post> createPost({
    required UserProfile author,
    required String caption,
    required List<File> imageFiles,
    File? videoFile,
  }) async {
    if (caption.trim().isEmpty && imageFiles.isEmpty && videoFile == null) {
      throw PostRepositoryException('Add a caption or media to post.');
    }

    final postId = _uuid.v4();
    final mediaUrls = <String>[];
    var mediaType = PostMediaType.none;

    for (var i = 0; i < imageFiles.length; i++) {
      final url = await _uploadMedia(
        uid: author.uid,
        postId: postId,
        file: imageFiles[i],
        fileName: 'image_$i.jpg',
        contentType: 'image/jpeg',
      );
      mediaUrls.add(url);
    }

    if (videoFile != null) {
      final url = await _uploadMedia(
        uid: author.uid,
        postId: postId,
        file: videoFile,
        fileName: 'video.mp4',
        contentType: 'video/mp4',
      );
      mediaUrls.add(url);
    }

    if (imageFiles.isNotEmpty && videoFile != null) {
      mediaType = PostMediaType.mixed;
    } else if (videoFile != null) {
      mediaType = PostMediaType.video;
    } else if (imageFiles.isNotEmpty) {
      mediaType = PostMediaType.image;
    }

    final post = Post(
      id: postId,
      authorId: author.uid,
      authorUsername: author.username,
      authorDisplayName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      country: author.country,
      region: author.region,
      caption: caption.trim(),
      mediaUrls: mediaUrls,
      mediaType: mediaType,
    );

    await _postRef(postId).set(post.toMap(forCreate: true));
    return post;
  }

  Future<String> _uploadMedia({
    required String uid,
    required String postId,
    required File file,
    required String fileName,
    required String contentType,
  }) async {
    final ref = _storage.ref(StoragePaths.postMedia(uid, postId, fileName));
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Returns `true` when the post is liked after the toggle.
  Future<bool> toggleLike({
    required String postId,
    required String uid,
  }) async {
    var liked = false;
    await _db.runTransaction((tx) async {
      final likeSnap = await tx.get(_likeRef(postId, uid));
      final postSnap = await tx.get(_postRef(postId));
      if (!postSnap.exists) {
        throw PostRepositoryException('Post not found.');
      }
      final likeCount = (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnap.exists) {
        tx.delete(_likeRef(postId, uid));
        tx.update(_postRef(postId), {
          'likeCount': likeCount > 0 ? likeCount - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        liked = false;
      } else {
        tx.set(_likeRef(postId, uid), {
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(_postRef(postId), {
          'likeCount': likeCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        liked = true;
      }
    });
    return liked;
  }

  Future<String?> getAuthorId(String postId) async {
    final snap = await _postRef(postId).get();
    if (!snap.exists) return null;
    return snap.data()?['authorId'] as String?;
  }

  Future<void> toggleSave({
    required String postId,
    required String uid,
  }) async {
    final ref = _saveRef(postId, uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<PostComment> addComment({
    required String postId,
    required UserProfile author,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw PostRepositoryException('Comment cannot be empty.');
    }

    final commentRef = _comments(postId).doc();
    final comment = PostComment(
      id: commentRef.id,
      postId: postId,
      authorId: author.uid,
      authorUsername: author.username,
      authorDisplayName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      text: trimmed,
    );

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(_postRef(postId));
      if (!postSnap.exists) {
        throw PostRepositoryException('Post not found.');
      }
      final commentCount =
          (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.set(commentRef, comment.toMap(forCreate: true));
      tx.update(_postRef(postId), {
        'commentCount': commentCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return comment;
  }

  Future<void> softDeletePost({
    required String postId,
    required String authorId,
  }) async {
    final snap = await _postRef(postId).get();
    if (!snap.exists) return;
    if (snap.data()?['authorId'] != authorId) {
      throw PostRepositoryException('You can only delete your own posts.');
    }
    await _postRef(postId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeleteComment({
    required String postId,
    required String commentId,
    required String authorId,
  }) async {
    final ref = _comments(postId).doc(commentId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()?['authorId'] != authorId) {
      throw PostRepositoryException('You can only delete your own comments.');
    }

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(_postRef(postId));
      final commentCount =
          (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.update(ref, {'isDeleted': true});
      if (postSnap.exists && commentCount > 0) {
        tx.update(_postRef(postId), {
          'commentCount': commentCount - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> reportContent({
    required String reporterId,
    required String targetType,
    required String targetId,
    String? reason,
  }) async {
    await _db.collection(FirestorePaths.moderationReports).add({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason ?? 'user_report',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}

class PostRepositoryException implements Exception {
  PostRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
