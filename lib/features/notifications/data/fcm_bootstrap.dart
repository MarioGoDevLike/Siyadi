import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../reputation/data/engagement_repositories.dart';

/// Requests notification permission and stores the FCM token on the user doc.
class FcmBootstrap {
  FcmBootstrap({
    required this.messaging,
    required this.notifications,
  });

  final FirebaseMessaging messaging;
  final NotificationRepository notifications;

  Future<void> setupForUser(String uid) async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // iOS / web may need APNS wait; ignore failures on unsupported platforms.
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await notifications.saveFcmToken(uid: uid, token: token);
      }

      messaging.onTokenRefresh.listen((t) {
        notifications.saveFcmToken(uid: uid, token: t);
      });
    } catch (e) {
      debugPrint('FCM setup skipped: $e');
    }
  }
}
