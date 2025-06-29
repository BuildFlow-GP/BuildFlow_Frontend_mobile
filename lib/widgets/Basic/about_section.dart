/// widgets/Basic/about_section.dart
library;

import 'package:flutter/material.dart';
import 'package:buildflow_frontend/themes/app_colors.dart'; // استيراد ملف الألوان

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديد أقصى عرض للمحتوى داخل هذا القسم
    final screenWidth = MediaQuery.of(context).size.width;
    final contentMaxWidth =
        screenWidth > 1300
            ? 1300.0
            : screenWidth * 0.95; // أقصى عرض 1000px أو 95% من عرض الشاشة

    return Center(
      // توسيط القسم بالكامل
      child: ConstrainedBox(
        // تحديد أقصى عرض للمحتوى الداخلي
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 24.0,
            horizontal: 8.0, // تقليل الهامش الجانبي قليلاً للعرض على الويب
          ),
          padding: const EdgeInsets.all(32.0), // Padding داخلي مريح أكثر
          decoration: BoxDecoration(
            color: AppColors.card, // لون خلفية من AppColors
            borderRadius: BorderRadius.circular(16.0), // حواف دائرية
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withAlpha((1 * 255).toInt()),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "About Us",
                style: TextStyle(
                  fontSize:
                      18, // حجم خط أكبر قليلاً ليظهر أوضح على الشاشات الكبيرة
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                "At BuildFlow, we believe great design starts with the right collaboration. "
                '\n'
                "Our platform bridges the gap between users, offices, and companies to streamline the journey from concept to construction. Whether you're planning a dream home, "
                "or designing an innovative workspace.\n BuildFlow empowers you with the tools and partnerships you need to succeed. "
                "With dynamic project tools, we’re reimagining how ideas become reality faster, smarter, and more connected than ever.",
                style: TextStyle(
                  fontSize: 13, // خط أوضح للويب
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.justify, // توسيط النص
              ),
            ],
          ),
        ),
      ),
    );
  }
}
