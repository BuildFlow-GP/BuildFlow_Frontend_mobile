// lib/screens/onboarding_screen.dart
import 'package:buildflow_frontend/screens/sign/signin_screen.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// -----------------------------------------------------------
// 1. OnboardingPageModel (Data Model for a Single Onboarding Page)
// -----------------------------------------------------------
class OnboardingPageModel {
  final String imagePath;
  final String title;
  final String description;

  OnboardingPageModel({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// -----------------------------------------------------------
// 2. OnboardingPageWidget (Widget for displaying a single onboarding page)
// -----------------------------------------------------------
class OnboardingPageWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height * 0.4,
            ),
          ),
          const SizedBox(height: 30),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color:
                  AppColors
                      .textPrimary, // Changed: استخدام لون النص الأساسي من AppColors
            ),
          ),
          const SizedBox(height: 15),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ), // Changed: استخدام لون النص الثانوي من AppColors
          ),
          const Expanded(flex: 1, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// 3. OnboardingScreen (The Main Onboarding Logic)
// -----------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _isLastPage = false;

  // بيانات صفحات التهيئة
  final List<OnboardingPageModel> onboardingPages = [
    OnboardingPageModel(
      // الصورة 1: شخص يفكر، يخطط، لديه أفكار وتصاميم.
      imagePath:
          'assets/step1.jpg', // تأكد أن هذا هو المسار الصحيح للصورة الأولى
      title: 'Transform Your Vision into Reality.', // حوّل رؤيتك إلى واقع.
      description:
          'Start your project journey by defining your ideas. BuildFlow connects homeowners with expert engineers to bring designs to life.',
      // الوصف: ابدأ رحلة مشروعك بتحديد أفكارك. BuildFlow يربط أصحاب المنازل بالمهندسين الخبراء لإحياء التصاميم.
    ),
    OnboardingPageModel(
      // الصورة 2: شخص يعمل على لابتوب، ويوجد مؤشر خطوات (1-2-3).
      imagePath:
          'assets/step2.jpg', // تأكد أن هذا هو المسار الصحيح للصورة الثانية
      title:
          'Navigate the Building Process with Ease.', // تنقّل في عملية البناء بسهولة.
      description:
          'Follow our guided steps to find trusted contractors, get transparent bids, and secure the best professionals for your project.',
      // الوصف: اتبع خطواتنا الموجهة لإيجاد مقاولين موثوقين، الحصول على عروض أسعار شفافة، وتأمين أفضل المختصين لمشروعك.
    ),
    OnboardingPageModel(
      // الصورة 3: شخص يعمل على لابتوب، ويوجد مؤشر تقدم وعناصر عمل (ساعة، ملفات).
      imagePath:
          'assets/step3.jpg', // تأكد أن هذا هو المسار الصحيح للصورة الثالثة
      title: 'Collaborate, Track, and Achieve.', // تعاون، تتبّع، وحقّق.
      description:
          'Manage all project communications, track progress in real-time, and ensure timely completion. BuildFlow empowers seamless cooperation.',
      // الوصف: أدر جميع اتصالات المشروع، تتبّع التقدم في الوقت الفعلي، وتأكد من الإنجاز في الوقت المحدد. BuildFlow يمكّن التعاون السلس.
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
        _isLastPage = _currentPageIndex == onboardingPages.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Added: تعيين لون خلفية Scaffold
      body: Stack(
        children: [
          // PageView to display the onboarding pages
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _isLastPage = _currentPageIndex == onboardingPages.length - 1;
              });
            },
            itemBuilder: (context, index) {
              final page = onboardingPages[index];
              return OnboardingPageWidget(
                imagePath: page.imagePath,
                title: page.title,
                description: page.description,
              );
            },
          ),

          // Page indicator and navigation buttons at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor:
                          AppColors
                              .accent, // Changed: لون النقطة النشطة هو accent
                      dotColor:
                          AppColors
                              .primary, // Changed: لون النقاط غير النشطة هو primary
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                      spacing: 5.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip Button
                      TextButton(
                        onPressed: () {
                          // Navigate to Sign In Screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                AppColors
                                    .textSecondary, // Changed: لون زر التخطي هو textSecondary
                          ),
                        ),
                      ),
                      // Next / Get Started Button
                      ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            // Navigate to User Type Selection Screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          } else {
                            // Otherwise, go to the next page
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor:
                              AppColors
                                  .accent, // Changed: لون خلفية الزر هو accent
                          foregroundColor:
                              Colors.white, // لون النص يبقى أبيض للتباين
                        ),
                        child: Text(
                          _isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
