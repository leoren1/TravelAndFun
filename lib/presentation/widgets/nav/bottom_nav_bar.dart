import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    return BottomAppBar(
      color: context.appColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: index == 0,
            onTap: () => context.go(AppRoutes.dashboard),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            label: 'Map',
            isSelected: index == 1,
            onTap: () => context.go(AppRoutes.map),
          ),
          _NavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Feed',
            isSelected: index == 2,
            onTap: () => context.go(AppRoutes.social),
          ),
          _NavItem(
            icon: Icons.bookmark_border_outlined,
            selectedIcon: Icons.bookmark,
            label: 'Plans',
            isSelected: index == 3,
            onTap: () => context.go(AppRoutes.plans),
          ),
          _NavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'My Page',
            isSelected: index == 4,
            onTap: () => context.go(AppRoutes.myPage),
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.map)) return 1;
    if (location.startsWith(AppRoutes.social)) return 2;
    if (location.startsWith(AppRoutes.plans)) return 3;
    if (location.startsWith(AppRoutes.myPage)) return 4;
    return 0;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? AppColors.primary : context.appColors.textMuted,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : context.appColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

