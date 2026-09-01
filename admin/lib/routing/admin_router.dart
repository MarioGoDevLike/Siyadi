import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_providers.dart';
import '../presentation/admin_shell.dart';
import '../presentation/admin_sign_in_page.dart';
import '../presentation/badges_page.dart';
import '../presentation/content_moderation_page.dart';
import '../presentation/locations_queue_page.dart';
import '../presentation/moderation_page.dart';
import '../presentation/overview_page.dart';
import '../presentation/users_page.dart';
import '../theme/admin_theme.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'admin-root');

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _GateRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(adminGateStatusProvider);
      final onSignIn = state.matchedLocation == '/sign-in';

      switch (status) {
        case AdminGateStatus.loading:
          return state.matchedLocation == '/loading' ? null : '/loading';
        case AdminGateStatus.signedOut:
          return onSignIn ? null : '/sign-in';
        case AdminGateStatus.notAdmin:
          return state.matchedLocation == '/forbidden' ? null : '/forbidden';
        case AdminGateStatus.ready:
          if (onSignIn ||
              state.matchedLocation == '/loading' ||
              state.matchedLocation == '/forbidden') {
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, __) => const AdminSignInPage(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, __) => Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gpp_bad_outlined,
                          size: 48, color: AdminColors.danger),
                      const SizedBox(height: 12),
                      Text(
                        'Not an admin',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This account is signed in but users/{uid}.isAdmin is not true. Update Firestore, then refresh.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            ref.read(adminRepositoryProvider).signOut(),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const OverviewPage()),
          GoRoute(
            path: '/locations',
            builder: (_, __) => const LocationsQueuePage(),
          ),
          GoRoute(
            path: '/moderation',
            builder: (_, __) => const ModerationPage(),
          ),
          GoRoute(
            path: '/content',
            builder: (_, __) => const ContentModerationPage(),
          ),
          GoRoute(path: '/users', builder: (_, __) => const UsersPage()),
          GoRoute(path: '/badges', builder: (_, __) => const BadgesPage()),
        ],
      ),
    ],
  );
});

class _GateRefresh extends ChangeNotifier {
  _GateRefresh(this.ref) {
    _sub = ref.listen(adminGateStatusProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
  late final ProviderSubscription<AdminGateStatus> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
