import 'package:flutter/material.dart';
import '../../models/Basic/office_model.dart'; // تأكدي من المسار الصحيح

class OfficeSuggestionCard extends StatelessWidget {
  // تم تحويله إلى StatelessWidget مبدئياً
  final OfficeModel office;
  final bool isFavorite; // مطلوب
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const OfficeSuggestionCard({
    super.key,
    required this.office,
    required this.isFavorite, // أصبح مطلوباً
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // للاحتفاظ بتأثيرات الـ hover، سنستخدم نفس النمط الذي اتبعناه مع CompanySuggestionCard
    return _OfficeSuggestionCardContent(
      office: office,
      isFavorite: isFavorite,
      onFavoriteToggle: onFavoriteToggle,
      onTap: onTap,
    );
  }
}

class _OfficeSuggestionCardContent extends StatefulWidget {
  final OfficeModel office;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const _OfficeSuggestionCardContent({
    required this.office,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<_OfficeSuggestionCardContent> createState() =>
      _OfficeSuggestionCardContentState();
}

class _OfficeSuggestionCardContentState
    extends State<_OfficeSuggestionCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isHovered ? 1.03 : 1.0;
    final double elevation = _isHovered ? 8.0 : 2.0;
    final Offset offset = _isHovered ? const Offset(0, -5) : Offset.zero;
    final Duration animationDuration = const Duration(milliseconds: 200);

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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                84,
                83,
                83,
              ).withOpacity(_isHovered ? 0.15 : 0.08),
              blurRadius: elevation * 2,
              spreadRadius: 0.5,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                        child:
                            widget.office.profileImage != null &&
                                    widget.office.profileImage!.isNotEmpty
                                ? Image.network(
                                  widget
                                      .office
                                      .profileImage!, // افترض أن هذا URL كامل
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.business,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  loadingBuilder: (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 120,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.business,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                      ),
                      if (widget.onFavoriteToggle != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap:
                                  widget
                                      .onFavoriteToggle, // استدعاء الدالة الممررة مباشرة
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons
                                          .favorite_border, // استخدام widget.isFavorite
                                  color:
                                      widget.isFavorite
                                          ? Colors.redAccent
                                          : Colors.white,
                                  size: 26,
                                  shadows:
                                      _isHovered || !widget.isFavorite
                                          ? [
                                            const Shadow(
                                              blurRadius: 3.0,
                                              color: Colors.black54,
                                              offset: Offset(0, 1),
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
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.office.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        if (widget.office.location != null &&
                            widget.office.location!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  widget.office.location ?? '',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4.0),
                        if (widget.office.rating != null)
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16.0,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                widget.office.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*
// screens/widgets/office_suggestion_card.dart (أو مسار هذا الملف الخاص بك)
import 'package:flutter/material.dart';
import 'package:buildflow_frontend/themes/app_colors.dart'; // استيراد ملف الألوان
import '../../models/Basic/office_model.dart'; // تأكدي من المسار الصحيح لـ OfficeModel
import '../../utils/constants.dart'; // استيراد Constants لـ Base URL، تأكدي من وجوده ومساره الصحيح

class OfficeSuggestionCard extends StatelessWidget {
  final OfficeModel office;
  final bool isFavorite; // مطلوب لتحديد حالة المفضلة
  final VoidCallback? onFavoriteToggle; // دالة للتبديل بين المفضلة
  final VoidCallback? onTap; // دالة للضغط على الكارت بالكامل

  const OfficeSuggestionCard({
    super.key,
    required this.office,
    required this.isFavorite, // أصبح مطلوباً
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // للاحتفاظ بتأثيرات الـ hover، سنستخدم نفس النمط الذي اتبعناه مع CompanySuggestionCard
    return _OfficeSuggestionCardContent(
      office: office,
      isFavorite: isFavorite,
      onFavoriteToggle: onFavoriteToggle,
      onTap: onTap,
    );
  }
}

class _OfficeSuggestionCardContent extends StatefulWidget {
  final OfficeModel office;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const _OfficeSuggestionCardContent({
    required this.office,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<_OfficeSuggestionCardContent> createState() =>
      _OfficeSuggestionCardContentState();
}

class _OfficeSuggestionCardContentState
    extends State<_OfficeSuggestionCardContent> {
  bool _isHovered = false; // حالة الـ hover للتحكم في التأثيرات البصرية

  @override
  Widget build(BuildContext context) {
    // تأثيرات التكبير والظل والحركة عند الـ hover
    final double scale = _isHovered ? 1.03 : 1.0;
    final double elevation = _isHovered ? 8.0 : 2.0;
    final Offset offset = _isHovered ? const Offset(0, -5) : Offset.zero;
    final Duration animationDuration = const Duration(milliseconds: 200);

    // بناء مسار الصورة الكامل للمكتب.
    // يتم التحقق مما إذا كان المسار يبدأ بـ 'http' (أي URL كامل)،
    // وإلا فإنه يضيف Constants.baseUrl لجعله كاملاً.
    String? officeImageUrl;
    if (widget.office.profileImage != null &&
        widget.office.profileImage!.isNotEmpty) {
      if (widget.office.profileImage!.startsWith('http') ||
          widget.office.profileImage!.startsWith('https')) {
        officeImageUrl = widget.office.profileImage!; // URL كامل
      } else {
        officeImageUrl =
            '${Constants.baseUrl}/${widget.office.profileImage}'; // مسار نسبي
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), // تفعيل حالة الـ hover
      onExit: (_) => setState(() => _isHovered = false), // تعطيل حالة الـ hover
      cursor: SystemMouseCursors.click, // تغيير شكل المؤشر عند الـ hover
      child: AnimatedContainer(
        duration: animationDuration, // مدة التحريك
        transformAlignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..translate(offset.dx, offset.dy) // تطبيق حركة للأعلى
              ..scale(scale), // تطبيق التكبير
        // هنا نقوم بتطبيق الظل والخلفية للكارت الخارجي
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color:
              AppColors
                  .card, // لون خلفية الكارت من AppColors (سيتم تحديثه في ملف app_colors.dart)
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(
                _isHovered ? 0.2 : 0.1,
              ), // لون ظل من AppColors، أغمق عند الـ hover
              blurRadius: elevation * 2, // زيادة الـ blur عند الـ hover
              spreadRadius: 0.5,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap, // استدعاء دالة onTap الممررة للكارت بالكامل
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: 220, // **تحديد عرض ثابت للكارت كما طلبت**
            // يمكنك إضافة minHeight إذا أردت ضمان ارتفاع أدنى
            // constraints: const BoxConstraints(minHeight: 220),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // محاذاة العناصر لليسار
              children: <Widget>[
                Stack(
                  alignment:
                      Alignment
                          .topRight, // أيقونة المفضلة في الزاوية العلوية اليمنى
                  children: [
                    // صورة المكتب مع حواف دائرية علوية
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child:
                          (officeImageUrl != null && officeImageUrl.isNotEmpty)
                              ? Image.network(
                                officeImageUrl, // استخدام مسار الصورة الكامل
                                height: 120, // ارتفاع ثابت للصورة
                                width:
                                    double.infinity, // الصورة تملأ عرض الكارت
                                fit:
                                    BoxFit
                                        .cover, // الصورة تغطي المساحة مع الحفاظ على الأبعاد
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      // بديل في حالة فشل تحميل الصورة
                                      height: 120,
                                      color:
                                          AppColors
                                              .background, // لون خلفية الخطأ من AppColors
                                      child: Center(
                                        child: Icon(
                                          Icons
                                              .business_rounded, // أيقونة مكتب بتصميم أحدث
                                          size: 40,
                                          color:
                                              AppColors
                                                  .textSecondary, // لون الأيقونة من AppColors
                                        ),
                                      ),
                                    ),
                                loadingBuilder: (
                                  BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    // مؤشر تحميل الصورة
                                    height: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ), // لون مؤشر التحميل من AppColors
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Container(
                                // بديل في حالة عدم وجود URL للصورة
                                height: 120,
                                color:
                                    AppColors
                                        .background, // لون خلفية افتراضية من AppColors
                                child: Center(
                                  child: Icon(
                                    Icons.business_rounded, // أيقونة افتراضية
                                    size: 40,
                                    color:
                                        AppColors
                                            .textSecondary, // لون من AppColors
                                  ),
                                ),
                              ),
                    ),
                    // زر المفضلة
                    if (widget.onFavoriteToggle != null)
                      Positioned(
                        top: 8, // مسافة من الأعلى
                        right: 8, // مسافة من اليمين
                        child: Material(
                          color:
                              Colors.transparent, // لجعل خلفية Material شفافة
                          borderRadius: BorderRadius.circular(
                            24,
                          ), // حواف دائرية للـ InkWell
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap:
                                widget
                                    .onFavoriteToggle, // استدعاء دالة تبديل المفضلة
                            child: Padding(
                              padding: const EdgeInsets.all(
                                8.0,
                              ), // Padding حول الأيقونة لزيادة منطقة الضغط
                              child: Icon(
                                widget.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons
                                        .favorite_border_rounded, // أيقونات بتصميم أحدث
                                color:
                                    widget.isFavorite
                                        ? Colors
                                            .redAccent // اللون الأحمر التقليدي للمفضلة
                                        : AppColors
                                            .background, // لون الأيقونة غير المفضلة (لتظهر بوضوح فوق الصورة)
                                size: 28, // حجم أكبر للأيقونة
                                shadows: [
                                  // إضافة ظل دائم للأيقونة لجعلها تبرز
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: AppColors.shadow.withOpacity(
                                      0.5,
                                    ), // ظل من AppColors
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(
                    12.0,
                  ), // Padding للنصوص داخل الكارت
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // محاذاة النصوص لليسار
                    children: <Widget>[
                      // اسم المكتب
                      Text(
                        widget.office.name,
                        style: TextStyle(
                          fontSize: 18.0, // حجم خط أكبر
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary, // لون نص من AppColors
                        ),
                        maxLines: 1, // سطر واحد فقط
                        overflow:
                            TextOverflow.ellipsis, // إضافة ... إذا تجاوز النص
                      ),
                      const SizedBox(height: 6.0), // مسافة بين الاسم والموقع
                      // موقع المكتب (إذا كان موجوداً)
                      if (widget.office.location != null &&
                          widget.office.location!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined, // أيقونة الموقع
                              size: 16, // حجم أيقونة مناسب
                              color:
                                  AppColors.textSecondary, // لون من AppColors
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              // استخدام Expanded لمنع الـ overflow للنص
                              child: Text(
                                widget.office.location ?? '',
                                style: TextStyle(
                                  fontSize: 13.0, // حجم خط مناسب
                                  color:
                                      AppColors
                                          .textSecondary, // لون من AppColors
                                ),
                                maxLines: 1, // سطر واحد فقط
                                overflow:
                                    TextOverflow
                                        .ellipsis, // إضافة ... إذا تجاوز النص
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6.0), // مسافة بين الموقع والتقييم
                      // تقييم المكتب (إذا كان موجوداً)
                      if (widget.office.rating != null)
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.star_rounded, // أيقونة نجمة بتصميم أحدث
                              color: Colors.amber.shade700, // لون أغمق للنجمة
                              size: 18.0, // حجم أيقونة مناسب
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              widget.office.rating!.toStringAsFixed(
                                1,
                              ), // عرض منزلة عشرية واحدة
                              style: TextStyle(
                                fontSize: 13.0, // حجم خط مناسب
                                color:
                                    AppColors
                                        .textPrimary, // لون نص من AppColors
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/
