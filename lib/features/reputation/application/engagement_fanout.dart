import '../../../core/constants/app_constants.dart';
import '../../../data/models/engagement.dart';
import '../../../data/models/user_profile.dart';
import '../data/engagement_repositories.dart';

/// Fan-out for reputation, badges, and in-app notifications after social actions.
class EngagementFanout {
  EngagementFanout({
    required this.reputation,
    required this.notifications,
    required this.badges,
  });

  final ReputationRepository reputation;
  final NotificationRepository notifications;
  final BadgeRepository badges;

  Future<void> onFieldReportCreated(UserProfile author) async {
    await reputation.award(
      targetUid: author.uid,
      actorUid: author.uid,
      action: ReputationAction.fieldReport,
      sourceId: 'report_${DateTime.now().millisecondsSinceEpoch}',
    );
    await badges.ensureBadge(
      userId: author.uid,
      badgeId: 'first_field_report',
      badgeName: 'First Field Report',
    );
    final count = await badges.countFieldReportsToday(author.uid);
    if (count >= 3) {
      await badges.ensureBadge(
        userId: author.uid,
        badgeId: 'weekly_reporter',
        badgeName: 'Weekly Field Scout',
      );
    }
  }

  Future<void> onPostCreated(UserProfile author) async {
    await reputation.award(
      targetUid: author.uid,
      actorUid: author.uid,
      action: ReputationAction.socialPost,
      sourceId: 'post_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> onPostLiked({
    required String actorUid,
    required String authorId,
    required String postId,
    required String actorName,
  }) async {
    if (actorUid == authorId) return;
    await reputation.award(
      targetUid: authorId,
      actorUid: actorUid,
      action: ReputationAction.receivedLike,
      sourceId: '${postId}_$actorUid',
    );
    await notifications.create(
      userId: authorId,
      type: 'reaction',
      title: '$actorName liked your post',
      route: AppRoutes.home,
    );
  }

  Future<void> onCommentAdded({
    required String actorUid,
    required String authorId,
    required String postId,
    required String actorName,
  }) async {
    if (actorUid == authorId) return;
    await reputation.award(
      targetUid: authorId,
      actorUid: actorUid,
      action: ReputationAction.receivedComment,
      sourceId: '${postId}_comment_$actorUid',
    );
    await notifications.create(
      userId: authorId,
      type: 'comment',
      title: '$actorName commented on your post',
      route: AppRoutes.postComments(postId),
    );
  }

  Future<void> onFollowed({
    required String followerId,
    required String followingId,
    required String followerName,
  }) async {
    await notifications.create(
      userId: followingId,
      type: 'follow',
      title: '$followerName started following you',
      route: AppRoutes.userProfile(followerId),
    );
  }

  Future<void> onMessageSent({
    required String conversationId,
    required String recipientId,
    required String senderId,
    required String preview,
    String senderName = 'Someone',
  }) async {
    await notifications.create(
      userId: recipientId,
      type: 'message',
      title: 'Message from $senderName',
      body: preview,
      route: AppRoutes.chat(conversationId),
    );
  }

  Future<void> onLocationReviewed({
    required String proposedBy,
    required String locationName,
    required bool approved,
    String? note,
  }) async {
    if (approved) {
      await reputation.award(
        targetUid: proposedBy,
        actorUid: proposedBy,
        action: ReputationAction.locationApproved,
        sourceId: 'loc_${locationName.hashCode}',
      );
      await badges.ensureBadge(
        userId: proposedBy,
        badgeId: 'map_contributor',
        badgeName: 'Map Contributor',
      );
    }
    await notifications.create(
      userId: proposedBy,
      type: 'location_review',
      title: approved
          ? 'Location approved: $locationName'
          : 'Location rejected: $locationName',
      body: note ?? '',
      route: AppRoutes.myLocationProposals,
    );
  }
}
