import 'screens/Basic/onboarding_screen.dart';
import 'themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
// import 'screens/sign/signin_screen.dart';
import 'package:get/get.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; //  للتحقق من kIsWeb

// import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // مهم قبل async init
  await GetStorage.init(); // ✅ تهيئة التخزين المحلي

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BuildFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey), // لون عنوان الحقل
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.accent, // لون المؤشر
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // لون النص داخل الحقول
        ),
      ),

      home: OnboardingScreen(),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'dart:developer';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     await Firebase.initializeApp();
//     print("✅ Firebase Initialized Successfully");
//   } catch (e) {
//     print("❌ Firebase Initialization Failed: $e");
//   }
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: Scaffold(body: Center(child: Text('Firebase Check'))),
//     );
//   }
// }
