import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/notifications/data/fcm_bootstrap.dart';
import 'features/reputation/application/engagement_providers.dart';

class SiyadiApp extends ConsumerWidget {
  const SiyadiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProfileProvider, (prev, next) {
      final profile = next.asData?.value;
      if (profile == null) return;
      if (!profile.privacy.pushNotificationsEnabled) return;
      if (ref.read(authGateStatusProvider) != AuthGateStatus.ready) return;
      FcmBootstrap(
        messaging: FirebaseMessaging.instance,
        notifications: ref.read(notificationRepositoryProvider),
      ).setupForUser(profile.uid);
    });

    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
