//  ملف جديد: screens/main_shell_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/navbar/custom_bottom_nav.dart';
import 'home_page.dart';
import 'basic/favorite.dart';
import 'basic/search.dart';
import 'basic/notifications_screen.dart';
import 'profiles/company_profile.dart';
import 'profiles/user_profile.dart';
import 'profiles/office_profile.dart';
import '../widgets/Navbar/drawer_wrapper.dart';

import '../services/session.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DrawerWrapper(child: HomeScreen()),
    DrawerWrapper(child: SearchScreen()),
    DrawerWrapper(child: FavoritesScreen()),
    DrawerWrapper(child: NotificationsScreen()),
  ];

  void _onItemTapped(int index) async {
    if (index == 4) {
      //  إذا تم الضغط على أيقونة البروفايل (الخامسة)
      String? userType = await Session.getUserType();
      int? entityId = await Session.getUserId();

      if (entityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to view your profile.")),
        );
        return;
      }

      Widget? profilePage;
      if (userType?.toLowerCase() == 'individual') {
        profilePage = UserProfileScreen(isOwner: true /*, userId: entityId */);
      } else if (userType?.toLowerCase() == 'office') {
        profilePage = OfficeProfileScreen(officeId: entityId, isOwner: true);
      } else if (userType?.toLowerCase() == 'company') {
        profilePage = CompanyProfileScreen(companyId: entityId, isOwner: true);
      }

      if (profilePage != null) {
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profilePage!),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile not available for your user type."),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: Center(
        //  عرض الشاشة المحددة من القائمة
        //  تأكدي أن _selectedIndex لا يتجاوز حدود القائمة
        child:
            _selectedIndex < _widgetOptions.length
                ? _widgetOptions.elementAt(_selectedIndex)
                : _widgetOptions.elementAt(0), //  عرض الهوم كاحتياط
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, //  استدعاء دالتنا عند الضغط
      ),
    );
  }
}
