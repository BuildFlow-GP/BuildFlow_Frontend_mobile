// widgets/bottom_nav_item.dart
import 'package:flutter/material.dart';

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex; //  يأتي من CustomBottomNav.currentIndex
  final Function(int) onTap; //  يأتي من CustomBottomNav.onTap

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  void _showTooltip(BuildContext context, String message) {
    // ... (كما هي)
  }

  @override
  Widget build(BuildContext context) {
    //  CurvedNavigationBar يتحكم في لون الأيقونة النشطة وغير النشطة من خلال خصائصه
    //  مثل color (للخلفية والأيقونات غير النشطة) و buttonBackgroundColor (لخلفية الزر النشط)
    //  لون الأيقونة النشطة عادة ما يكون لوناً متناقضاً مع buttonBackgroundColor
    //  ولون الأيقونة غير النشطة يكون لوناً متناقضاً مع color الخاص بالـ CurvedNavigationBar

    return InkWell(
      //  استخدام InkWell بدلاً من MouseRegion و GestureDetector لتبسيط الأمر ولتأثير الضغط
      onTap:
          () => onTap(
            index,
          ), //  ✅✅✅ استدعاء onTap الممررة مع الـ index الصحيح ✅✅✅
      onLongPress: () => _showTooltip(context, label),
      customBorder: const CircleBorder(), //  لجعل تأثير الضغط (ripple) دائرياً
      child: Tooltip(
        message: label,
        child: Icon(
          icon,
          size: 30,
          //  يمكنكِ ترك CurvedNavigationBar يتحكم في اللون، أو تحديدها هنا
          //  color: isSelected ? Colors.white : Colors.black54, //  مثال، قد تحتاجين لتعديل هذا
          //  بناءً على ألوان CurvedNavigationBar
        ),
      ),
    );
  }
}
