import 'signup_screen.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // شريط التنقل مع تأثير الظل واللون العصري
          Container(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                  color: AppColors.accent,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    "To Sign Up, Select Account Type",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // توازن المساحة بسبب زر الرجوع
              ],
            ),
          ),

          const SizedBox(height: 24),

          // القائمة الرئيسية ببطاقات تفاعلية بتأثير الظل والحركة
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: _IndividualCardMobile(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: _CompanyCardMobile(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: _OfficeCardMobile(),
                      ),
                    ],
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildResponsiveCard(
                            context,
                            const _IndividualCard(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildResponsiveCard(
                            context,
                            const _CompanyCard(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildResponsiveCard(
                            context,
                            const _OfficeCard(),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCard(BuildContext context, Widget card) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400, // Set a maximum width for the cards
        ),
        child: card,
      ),
    );
  }
}

// =============================================
// بطاقات الأجهزة الكبيرة مع تأثير الظل والانعكاس الحديث
// =============================================

class _IndividualCard extends StatelessWidget {
  const _IndividualCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Individual')),
          child: Hero(
            tag: 'Individual',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/individual.jpg',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Individual'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Company')),
          child: Hero(
            tag: 'Company',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/companyy.png',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Company'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Office')),
          child: Hero(
            tag: 'Office',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/officee.png',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Office'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================
// بطاقات الموبايل مع تدرجات لونية وتأثير ظل ناعم
// =============================================

class _IndividualCardMobile extends StatelessWidget {
  const _IndividualCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Individual')),
          child: Hero(
            tag: 'Individual',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/individual.jpg'),
                  _MobileCardTitle(title: 'Individual'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyCardMobile extends StatelessWidget {
  const _CompanyCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Company')),
          child: Hero(
            tag: 'Company',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/companyy.png'),
                  _MobileCardTitle(title: 'Company'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficeCardMobile extends StatelessWidget {
  const _OfficeCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => SignUpScreen(userType: 'Office')),
          child: Hero(
            tag: 'Office',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/officee.png'),
                  _MobileCardTitle(title: 'Office'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================
// المكونات المشتركة مع تحسينات في الخطوط والألوان
// =============================================

class _CardTitle extends StatelessWidget {
  final String title;
  const _CardTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      color: Colors.white,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary.withOpacity(0.85),
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _MobileCardImage extends StatelessWidget {
  final String imagePath;
  const _MobileCardImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

class _MobileCardTitle extends StatelessWidget {
  final String title;
  const _MobileCardTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withOpacity(0.85),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// == تأثير Hover حديث مع حركة رفع خفيفة ==
class _HoverEffect extends StatefulWidget {
  final Widget child;

  const _HoverEffect({required this.child});

  @override
  State<_HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<_HoverEffect> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final transform =
        _hovering
            ? (Matrix4.identity()..translate(0, -6, 0))
            : Matrix4.identity();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: transform,
        child: widget.child,
      ),
    );
  }
}
