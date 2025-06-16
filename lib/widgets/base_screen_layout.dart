// lib/widgets/base_screen_layout.dart

import 'package:flutter/material.dart';
import 'package:buildflow_frontend/widgets/Navbar/navbar.dart'; // استورد Navbar هنا

class BaseScreenLayout extends StatelessWidget {
  final Widget child; // محتوى الشاشة الفعلي
  final bool
  showNavbar; // لإتاحة خيار إظهار أو إخفاء Navbar (افتراضياً سيكون ظاهر)

  const BaseScreenLayout({
    super.key,
    required this.child,
    this.showNavbar = true, // الافتراضي: عرض Navbar
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showNavbar) const Navbar(), // هنا يتم عرض Navbar
        Expanded(
          // Expanded لجعل المحتوى يأخذ المساحة المتبقية
          child:
              child, // محتوى الشاشة الخاص (مثل محتوى صفحة البروفايل أو الرئيسية)
        ),
      ],
    );
  }
}
