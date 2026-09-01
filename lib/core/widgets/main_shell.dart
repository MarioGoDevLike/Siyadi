import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/create/presentation/create_action_sheet.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _onCreatePressed(BuildContext context) async {
    final action = await showCreateActionSheet(context);
    if (action == null || !context.mounted) return;

    switch (action) {
      case CreateAction.post:
        context.push(AppRoutes.createPost);
      case CreateAction.fieldReport:
        context.push(AppRoutes.createFieldReport);
      case CreateAction.proposeLocation:
        context.push(AppRoutes.proposeLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _CreateFab(onPressed: () => _onCreatePressed(context)),
      bottomNavigationBar: _SiyadiBottomBar(
        currentIndex: index,
        onSelect: _onDestinationSelected,
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'Create',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _SiyadiBottomBar extends StatelessWidget {
  const _SiyadiBottomBar({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.fog.withValues(alpha: 0.96),
      elevation: 0,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      padding: EdgeInsets.zero,
      height: 68,
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            selectedIcon: Icons.map_rounded,
            label: 'Map',
            selected: currentIndex == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 64),
          _NavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
            label: 'Market',
            selected: currentIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
            selected: currentIndex == 3,
            onTap: () => onSelect(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.canopy : AppColors.clay;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.canopy.withValues(alpha: 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
