import 'package:flutter/material.dart';
import '../../models/Basic/project_model.dart'; // أو ProjectSuggestionModel
import '../../themes/app_colors.dart'; // تأكد من استيراد ملف الألوان

class ProjectSuggestionCard extends StatelessWidget {
  final ProjectModel project;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProjectSuggestionCard({
    super.key,
    required this.project,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Note: The outer Container (with margin, color, boxShadow, borderRadius)
    // is now handled by _buildSuggestionSection in HomeScreen.
    // This widget should focus on its internal layout and animation.
    return _ProjectSuggestionCardContent(
      project: project,
      isFavorite: isFavorite,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
    );
  }
}

class _ProjectSuggestionCardContent extends StatefulWidget {
  final ProjectModel project;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const _ProjectSuggestionCardContent({
    required this.project,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<_ProjectSuggestionCardContent> createState() =>
      _ProjectSuggestionCardContentState();
}

class _ProjectSuggestionCardContentState
    extends State<_ProjectSuggestionCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isHovered ? 1.03 : 1.0;
    // ignore: unused_local_variable
    final double elevation = _isHovered ? 8.0 : 2.0;
    final Offset offset = _isHovered ? const Offset(0, -5) : Offset.zero;
    final Duration animationDuration = const Duration(milliseconds: 200);

    final String projectName = widget.project.name;
    final String? projectStatus = widget.project.status;
    final String? officeName = widget.project.office?.name;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: animationDuration,
        transformAlignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..translate(offset.dx, offset.dy)
              ..scale(scale),
        // **هنا التعديل الأهم:** تحديد عرض البطاقة هنا (وليس في Container/SizedBox داخلي)
        width: 250,

        // الارتفاع الكلي للبطاقة يتم التحكم به بشكل رئيسي من الـ SizedBox في HomeScreen (260)
        // لكننا نضمن أن المحتوى الداخلي يتناسب معه.

        // إزالة BoxDecoration من هنا، لأنه يتم إدارته من قبل HomeScreen
        // color: Theme.of(context).cardColor, // تم إزالة هذا
        // boxShadow: [ ... ], // تم إزالة هذا
        child: InkWell(
          onTap: widget.onTap,
          // يجب أن يتطابق borderRadius هنا مع borderRadius في HomeScreen
          borderRadius: BorderRadius.circular(
            16.0,
          ), // تم تعديل إلى 16.0 ليتناسق
          child: Padding(
            // استخدام Padding مباشرة لضبط المسافات الداخلية
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // لا تضع mainAxisAlignment: MainAxisAlignment.spaceBetween هنا مباشرة
              // الـ Expanded سيقوم بإدارة التباعد بشكل أفضل
              children: <Widget>[
                // قسم الصورة (إذا كان موجوداً في project_model)
                // يجب أن تكون أبعاد الصورة مقيدة
                // مثال (يجب أن يكون لديك حقل imageUrl في ProjectModel):
                // if (widget.project.imageUrl != null && widget.project.imageUrl!.isNotEmpty)
                //   Container(
                //     height: 100, // ارتفاع ثابت للصورة
                //     width: double.infinity,
                //     clipBehavior: Clip.hardEdge,
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(8.0),
                //     ),
                //     child: Image.network(
                //       widget.project.imageUrl!,
                //       fit: BoxFit.cover,
                //       errorBuilder: (context, error, stackTrace) =>
                //           Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
                //     ),
                //   ),
                // const SizedBox(height: 8.0), // تباعد بعد الصورة
                Expanded(
                  // هذا الـ Expanded مهم ليسمح للنص بأخذ المساحة المتبقية قبل زر المفضلة
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // **أهم تعديل:** إزالة mainAxisSize: MainAxisSize.min من هنا
                    // mainAxisSize: MainAxisSize.min, // لا تستخدم هذا مع Expanded
                    children: [
                      Text(
                        projectName,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // استخدام AppColors
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      if (projectStatus != null && projectStatus.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              size: 16,
                              color:
                                  AppColors.textSecondary, // استخدام AppColors
                            ),
                            const SizedBox(width: 4.0),
                            // استخدام Expanded هنا لتجنب الـ overflow للنص الطويل
                            Expanded(
                              child: Text(
                                'Status: $projectStatus',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color:
                                      AppColors
                                          .textSecondary, // استخدام AppColors
                                ),
                                maxLines: 1, // مهم لتجنب الـ overflow
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6.0),
                      if (officeName != null && officeName.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.business_center_outlined,
                              size: 16,
                              color:
                                  AppColors.textSecondary, // استخدام AppColors
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                'Office: $officeName',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color:
                                      AppColors
                                          .textSecondary, // استخدام AppColors
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // Spacer هنا يدفع زر المفضلة للأسفل إذا كان هناك مساحة
                      const Spacer(), // مهم لدفع زر المفضلة للأسفل
                    ],
                  ),
                ),
                // زر المفضلة
                if (widget.onFavoriteToggle != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onFavoriteToggle,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                widget.isFavorite
                                    ? AppColors
                                        .error // استخدام AppColors.error
                                    : AppColors
                                        .textSecondary, // استخدام AppColors
                            size: 26,
                            shadows:
                                _isHovered || !widget.isFavorite
                                    ? [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: AppColors.shadow.withOpacity(
                                          0.5,
                                        ), // استخدام AppColors
                                        offset: const Offset(0, 0.5),
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



/*
import 'package:flutter/material.dart';
import '../../models/Basic/project_model.dart'; // أو ProjectSuggestionModel
import '../../themes/app_colors.dart'; // تأكد من استيراد ملف الألوان

class ProjectSuggestionCard extends StatelessWidget {
  final ProjectModel project;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ProjectSuggestionCard({
    super.key,
    required this.project,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ProjectSuggestionCardContent(
      project: project,
      isFavorite: isFavorite,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
    );
  }
}

class _ProjectSuggestionCardContent extends StatefulWidget {
  final ProjectModel project;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const _ProjectSuggestionCardContent({
    required this.project,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<_ProjectSuggestionCardContent> createState() =>
      _ProjectSuggestionCardContentState();
}

class _ProjectSuggestionCardContentState
    extends State<_ProjectSuggestionCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isHovered ? 1.03 : 1.0;
    final double elevation = _isHovered ? 8.0 : 2.0;
    final Offset offset = _isHovered ? const Offset(0, -5) : Offset.zero;
    final Duration animationDuration = const Duration(milliseconds: 200);

    final String projectName = widget.project.name;
    final String? projectStatus = widget.project.status;
    final String? officeName = widget.project.office?.name;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: animationDuration,
        transformAlignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..translate(offset.dx, offset.dy)
              ..scale(scale),
        width: 250, // هذا العرض يتم تحديده هنا الآن بشكل صحيح

        // لا يوجد ارتفاع هنا. الارتفاع سيتم تحديده من خلال الـ SizedBox في HomeScreen (260)
        // والمحتوى الداخلي للبطاقة سيتمدد ليناسبه.
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16.0), // يتطابق مع HomeScreen
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // **التعديل هنا:** Spacer أصبح هنا، وليس داخل الـ Expanded
              children: <Widget>[
                // إذا كان لديك صورة للمشروع، ضعها هنا بأبعاد محددة
                // مثال:
                // if (widget.project.imageUrl != null && widget.project.imageUrl!.isNotEmpty)
                //   Container(
                //     height: 100, // ارتفاع ثابت للصورة
                //     width: double.infinity,
                //     clipBehavior: Clip.hardEdge,
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(8.0),
                //     ),
                //     child: Image.network(
                //       widget.project.imageUrl!,
                //       fit: BoxFit.cover,
                //       errorBuilder: (context, error, stackTrace) =>
                //           Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
                //     ),
                //   ),
                // const SizedBox(height: 8.0), // تباعد بعد الصورة
                Expanded(
                  // هذا الـ Expanded مهم لضمان أن النصوص تأخذ المساحة المتبقية
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // **أهم تعديل:** إزالة mainAxisSize: MainAxisSize.min
                    // mainAxisSize: MainAxisSize.min, // تم إزالة هذا السطر
                    children: [
                      Text(
                        projectName,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      if (projectStatus != null && projectStatus.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              // Expanded للنص لتجنب overflow أفقي
                              child: Text(
                                'Status: $projectStatus',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6.0),
                      if (officeName != null && officeName.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.business_center_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4.0),
                            Expanded(
                              // Expanded للنص لتجنب overflow أفقي
                              child: Text(
                                'Office: $officeName',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // لا يوجد Spacer() هنا. المساحة المتبقية يتم التعامل معها بواسطة Expanded
                    ],
                  ),
                ),
                const Spacer(), // **هنا مكان Spacer() الجديد!** يدفع المحتوى وزر المفضلة
                // زر المفضلة
                if (widget.onFavoriteToggle != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onFavoriteToggle,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                widget.isFavorite
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                            size: 26,
                            shadows:
                                _isHovered || !widget.isFavorite
                                    ? [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: AppColors.shadow.withOpacity(
                                          0.5,
                                        ),
                                        offset: const Offset(0, 0.5),
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/