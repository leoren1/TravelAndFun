import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: const _VerifyFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      color: AppColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
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
          const SizedBox(width: 56),
          _NavItem(
            icon: Icons.location_city_outlined,
            selectedIcon: Icons.location_city,
            label: 'Cities',
            isSelected: index == 2,
            onTap: () => context.go(AppRoutes.cities),
          ),
          _NavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            isSelected: index == 3,
            onTap: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.map)) return 1;
    if (location.startsWith(AppRoutes.cities)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
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
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyFab extends StatelessWidget {
  const _VerifyFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showActionSheet(context),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Verify a Visit',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Select a place from Category Detail to verify.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
