import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_providers.dart';
import '../theme/admin_theme.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (path: '/', label: 'Overview', icon: Icons.dashboard_outlined),
    (path: '/locations', label: 'Locations', icon: Icons.place_outlined),
    (path: '/moderation', label: 'Reports', icon: Icons.flag_outlined),
    (path: '/content', label: 'Content', icon: Icons.article_outlined),
    (path: '/users', label: 'Users', icon: Icons.people_outline),
    (path: '/badges', label: 'Badges', icon: Icons.military_tech_outlined),
  ];

  int _indexFor(String location) {
    final i = _destinations.indexWhere(
      (d) => d.path == location || (d.path != '/' && location.startsWith(d.path)),
    );
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFor(location);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width > 1100,
            selectedIndex: selected,
            onDestinationSelected: (i) => context.go(_destinations[i].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'SIYADI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AdminColors.brass,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Sign out',
              onPressed: () => ref.read(adminRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
