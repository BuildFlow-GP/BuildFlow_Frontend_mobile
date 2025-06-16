import 'package:flutter/material.dart';
// أو الصفحة الرئيسية
import 'package:buildflow_frontend/widgets/Navbar/app_drawer.dart';

class DrawerWrapper extends StatelessWidget {
  final Widget child;

  const DrawerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(key: _scaffoldKey, drawer: const AppDrawer(), body: child);
  }

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  static void openDrawer(BuildContext context) {
    if (_scaffoldKey.currentState != null &&
        !_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }
}
