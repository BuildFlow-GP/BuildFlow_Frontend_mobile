import 'package:buildflow_frontend/screens/Design/choose_office.dart';
import 'package:buildflow_frontend/screens/chat/chat_list_screen.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../super/select_project_supervision.dart';

class TypeOfProjectPage extends StatelessWidget {
  const TypeOfProjectPage({super.key});

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
                    "Choose Project Type",
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
                        child: _DesignCardMobile(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: _SupervisionCardMobile(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: _ConsultationCardMobile(),
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
                            const _DesignCard(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildResponsiveCard(
                            context,
                            const _SupervisionCard(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildResponsiveCard(
                            context,
                            const _ConsultationCard(),
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

class _DesignCard extends StatelessWidget {
  const _DesignCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => const ChooseOfficeScreen()),
          child: Hero(
            tag: 'project_Design',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/design.jpg',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Design'),
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

class _SupervisionCard extends StatelessWidget {
  const _SupervisionCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => const SelectProjectForSupervisionScreen()),
          child: Hero(
            tag: 'project_Supervision',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/supervision.jpg',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Supervision'),
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

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => const ChatListScreen()),
          child: Hero(
            tag: 'project_Consultation',
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              shadowColor: AppColors.primary.withOpacity(0.3),
              child: Container(
                constraints: BoxConstraints(maxHeight: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/consultation.jpg',
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    _CardTitle(title: 'Consultation'),
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

class _DesignCardMobile extends StatelessWidget {
  const _DesignCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => const ChooseOfficeScreen()),
          child: Hero(
            tag: 'project_Design',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/design.jpg'),
                  _MobileCardTitle(title: 'Design'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupervisionCardMobile extends StatelessWidget {
  const _SupervisionCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.to(() => const SelectProjectForSupervisionScreen()),
          child: Hero(
            tag: 'project_Supervision',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/supervision.jpg'),
                  _MobileCardTitle(title: 'Supervision'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsultationCardMobile extends StatelessWidget {
  const _ConsultationCardMobile();

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: 1.0,
      child: _HoverEffect(
        child: GestureDetector(
          onTap: () => Get.toNamed('/consultation-page'),
          child: Hero(
            tag: 'project_Consultation',
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: const [
                  _MobileCardImage(imagePath: 'assets/consultation.jpg'),
                  _MobileCardTitle(title: 'Consultation'),
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
