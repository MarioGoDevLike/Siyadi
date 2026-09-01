/// Canonical Firestore collection / path names for SIYADI.
abstract final class FirestorePaths {
  static const users = 'users';
  static const usernames = 'usernames';
  static const posts = 'posts';
  static const comments = 'comments';
  static const follows = 'follows';
  static const fieldReports = 'field_reports';
  static const huntingLocations = 'hunting_locations';
  static const marketplaceListings = 'marketplace_listings';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const badges = 'badges';
  static const userBadges = 'user_badges';
  static const moderationReports = 'moderation_reports';

  static String user(String uid) => '$users/$uid';
  static String username(String usernameLower) => '$usernames/$usernameLower';
  static String post(String id) => '$posts/$id';
  static String postComments(String postId) => '$posts/$postId/$comments';
  static String conversationMessages(String conversationId) =>
      '$conversations/$conversationId/$messages';
}

/// Firebase Storage path helpers.
abstract final class StoragePaths {
  static String userAvatar(String uid, String fileName) =>
      'users/$uid/avatar/$fileName';
  static String postMedia(String uid, String postId, String fileName) =>
      'users/$uid/posts/$postId/$fileName';
  static String fieldReportMedia(String uid, String reportId, String fileName) =>
      'users/$uid/field_reports/$reportId/$fileName';
  static String locationMedia(String uid, String locationId, String fileName) =>
      'users/$uid/locations/$locationId/$fileName';
  static String listingMedia(String uid, String listingId, String fileName) =>
      'users/$uid/marketplace/$listingId/$fileName';
}
