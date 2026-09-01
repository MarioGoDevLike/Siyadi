import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/field_reports/presentation/create_field_report_screen.dart';
import '../../features/field_reports/presentation/field_reports_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/location_detail_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/map/presentation/my_location_proposals_screen.dart';
import '../../features/map/presentation/propose_location_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/posts/presentation/comments_screen.dart';
import '../../features/posts/presentation/create_post_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/follow_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authGateStatusProvider);
      final loc = state.matchedLocation;

      final onAuth = loc == AppRoutes.signIn ||
          loc == AppRoutes.signUp ||
          loc == AppRoutes.forgotPassword;
      final onOnboarding = loc == AppRoutes.onboarding;
      final onSplash = loc == AppRoutes.splash;

      switch (status) {
        case AuthGateStatus.loading:
          return onSplash ? null : AppRoutes.splash;
        case AuthGateStatus.signedOut:
          if (onAuth) return null;
          return AppRoutes.signIn;
        case AuthGateStatus.needsOnboarding:
          if (onOnboarding) return null;
          return AppRoutes.onboarding;
        case AuthGateStatus.ready:
          if (onAuth || onOnboarding || onSplash) return AppRoutes.home;
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _AuthSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        name: 'create-post',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.createFieldReport,
        name: 'create-field-report',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateFieldReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.fieldReports,
        name: 'field-reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FieldReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.proposeLocation,
        name: 'propose-location',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProposeLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.myLocationProposals,
        name: 'my-location-proposals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyLocationProposalsScreen(),
      ),
      GoRoute(
        path: '/map/location/:locationId',
        name: 'location-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['locationId']!;
          return LocationDetailScreen(locationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.messages,
        name: 'messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConversationsScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'chat',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['conversationId']!;
              return ChatScreen(conversationId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/posts/:postId/comments',
        name: 'post-comments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['postId']!;
          return CommentsScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/u/:uid',
        name: 'user-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return UserProfileScreen(uid: uid);
        },
        routes: [
          GoRoute(
            path: 'followers',
            name: 'user-followers',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final uid = state.pathParameters['uid']!;
              return FollowListScreen(
                uid: uid,
                type: FollowListType.followers,
              );
            },
          ),
          GoRoute(
            path: 'following',
            name: 'user-following',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final uid = state.pathParameters['uid']!;
              return FollowListScreen(
                uid: uid,
                type: FollowListType.following,
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                name: 'map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.marketplace,
                name: 'marketplace',
                builder: (context, state) => const MarketplaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this.ref) {
    _authSub = ref.listen(authGateStatusProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription<AuthGateStatus> _authSub;

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }
}

class _AuthSplashScreen extends StatelessWidget {
  const _AuthSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.dawnWash),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SIYADI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bark,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: AppColors.canopy),
            ],
          ),
        ),
      ),
    );
  }
}
