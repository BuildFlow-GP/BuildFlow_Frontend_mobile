// lib/widgets/custom_bottom_nav.dart
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'bottom_nav_item.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: AppColors.primary,
      buttonBackgroundColor: Colors.white.withAlpha((0.85 * 255).round()),
      height: 60,
      animationDuration: const Duration(milliseconds: 300),
      index: currentIndex,
      onTap: onTap,
      items: [
        BottomNavItem(
          icon: Icons.home,
          label: 'Home',
          index: 0,
          selectedIndex: currentIndex,
          onTap: onTap,
        ),
        BottomNavItem(
          icon: Icons.search,
          label: 'Search',
          index: 1,
          selectedIndex: currentIndex,
          onTap: onTap,
        ),
        BottomNavItem(
          icon: Icons.favorite,
          label: 'Favorites',
          index: 2,
          selectedIndex: currentIndex,
          onTap: onTap,
        ),
        BottomNavItem(
          icon: Icons.notifications,
          label: 'Notifications',
          index: 3,
          selectedIndex: currentIndex,
          onTap: onTap,
        ),
        BottomNavItem(
          icon: Icons.person,
          label: 'Profile',
          index: 4,
          selectedIndex: currentIndex,
          onTap: onTap,
        ),
      ],
    );
  }
}
