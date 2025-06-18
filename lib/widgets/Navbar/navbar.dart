import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:buildflow_frontend/services/session.dart';
import 'package:buildflow_frontend/screens/sign/signin_screen.dart';

import '../../screens/chat/chat_list_screen.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  static const List<Map<String, dynamic>> navItems = [
    {'label': 'About Us', 'icon': Icons.info},
    {'label': 'Contact Us', 'icon': Icons.contact_page},
    {'label': 'Chat', 'icon': Icons.chat},
    {'label': 'Logout', 'icon': Icons.logout},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return isMobile
        ? _buildMobileNavbar(context)
        : _buildDesktopNavbar(context);
  }

  Widget _buildDesktopNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: InkWell(
              onTap: _navigateToHome,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'app-logo',
                      child: Image.asset(
                        'assets/logoo.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ...navItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _navItem(
                        item['label'],
                        () => _handleNavTap(item['label'], context),
                        isMobile: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavbar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 4,
      title: InkWell(
        onTap: _navigateToHome,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Hero(
                tag: 'app-logo',
                child: Image.asset(
                  'assets/logoo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ],
    );
  }

  Widget _navItem(String label, VoidCallback onTap, {bool isMobile = false}) {
    final item = navItems.firstWhere((item) => item['label'] == label);

    return isMobile
        ? InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        )
        : TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
  }

  void _navigateToHome() {
    Get.until((route) => route.isFirst);
  }

  Future<void> _handleNavTap(String label, BuildContext context) async {
    switch (label) {
      case 'About Us':
        Get.toNamed('/about-us');
        break;
      case 'Contact Us':
        Get.toNamed('/contact-us');
        break;
      case 'Chat':
        final userId = await Session.getUserId();
        if (userId != null) {
          Get.offAll(() => ChatListScreen());
        } else {
          Get.snackbar('Error', 'User ID not found.');
        }
        break;
      case 'Logout':
        await Session.clear();
        Get.offAll(() => const SignInScreen());
        break;
    }
  }
}

class NavDrawer extends StatefulWidget {
  final Function(String) onItemTap;
  final bool isOpen;

  const NavDrawer({super.key, required this.onItemTap, required this.isOpen});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 0,
      end: MediaQuery.of(context).size.width * 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant NavDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Drawer(
              backgroundColor: AppColors.primary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.zero),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => widget.onItemTap('Home'),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'app-logo',
                              child: Image.asset(
                                'assets/logoo.png',
                                width: 50,
                                height: 50,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'BuildFlow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: Navbar.navItems.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                        itemBuilder: (context, index) {
                          final item = Navbar.navItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ListTile(
                              leading: Icon(
                                item['icon'] as IconData,
                                color: Colors.white,
                              ),
                              title: Text(
                                item['label'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => widget.onItemTap(item['label']),
                              tileColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
