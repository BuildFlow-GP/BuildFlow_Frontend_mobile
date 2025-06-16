// screens/choose_office_screen.dart
import 'package:buildflow_frontend/themes/app_colors.dart'; // مسار ملف الألوان الخاص بك
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/Basic/project_model.dart'; // تأكد من وجود هذا الموديل ومساره الصحيح
import '../../services/create/chosen_office_service.dart'; // تأكد من وجود هذا السيرفس ومساره الصحيح
import '../../services/create/project_service.dart'; // تأكد من وجود هذا السيرفس ومساره الصحيح
import '../../utils/constants.dart'; // استيراد Constants لمسار الصور، تأكد من وجوده
// import 'no_permit_screen.dart'; // تعليق كما هو في كودك

final logger = Logger();

class ChooseOfficeScreen extends StatefulWidget {
  const ChooseOfficeScreen({super.key});

  @override
  State<ChooseOfficeScreen> createState() => _ChooseOfficeScreenState();
}

class _ChooseOfficeScreenState extends State<ChooseOfficeScreen> {
  // تأكد من أن `Office` class متاح من خلال الاستيرادات الخاصة بك
  List<Office> _offices = [];
  List<Office> _filteredOffices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Office? _selectedOffice;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    // Start loading state
    if (mounted) setState(() => _isLoading = true);

    try {
      // استدعاء السيرفس الأصلي الخاص بك لجلب المكاتب
      // تأكد أن `OfficeService` متاح عبر استيراد `chosen_office_service.dart` أو استيراد آخر
      final offices = await OfficeService.fetchSuggestedOffices();
      // Update state with fetched data
      if (mounted) {
        setState(() {
          _offices = offices;
          _filteredOffices = offices;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Failed to load offices: $e');
      // Show error to user
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load offices: ${e.toString()}'),
            backgroundColor: AppColors.error, // استخدام لون الخطأ من AppColors
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredOffices =
          _offices.where((office) {
            return office.name.toLowerCase().contains(_searchQuery) ||
                office.location.toLowerCase().contains(_searchQuery);
          }).toList();
      // Reset selection if filtered list does not contain the selected office
      if (_selectedOffice != null &&
          !_filteredOffices.contains(_selectedOffice)) {
        _selectedOffice = null;
      }
    });
  }

  void _onOfficeTapped(Office office) {
    setState(() {
      _selectedOffice = office;
    });
    logger.i('Tapped office: ${office.name}');
  }

  bool _isSubmittingRequest = false;
  bool get isSubmittingRequest =>
      _isSubmittingRequest; // Get-only property to check submission status

  void _onNextPressed() async {
    // Prevent action if no office is selected or another request is in progress
    if (_selectedOffice == null || _isSubmittingRequest) return;

    setState(() {
      _isSubmittingRequest = true; // إظهار التحميل
    });

    try {
      // يمكنكِ جمع projectType و initialDescription من المستخدم هنا إذا لزم الأمر
      // أو استخدام قيم افتراضية مؤقتاً للاختبار
      String projectType = "Initial Design Request"; // مثال، يجب تغييره
      String? initialDescription =
          "User is requesting an initial design from ${_selectedOffice!.name}."; // مثال

      // استدعاء السيرفس لإرسال الطلب
      final ProjectService projectService = ProjectService();
      // تأكد من أن ProjectService لديه دالة requestInitialProject
      final ProjectModel initialProject = await projectService
          .requestInitialProject(
            officeId: _selectedOffice!.id,
            projectType: projectType,
            initialDescription: initialDescription,
          );

      // نجاح
      if (mounted) {
        logger.i(
          'Initial project request sent successfully for office: ${_selectedOffice!.name}, Project ID: ${initialProject.id}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Project request sent to ${_selectedOffice!.name}. Waiting for approval.',
            ),
            backgroundColor:
                AppColors.success, // استخدام لون النجاح من AppColors
          ),
        );
        // يمكنكِ الانتقال إلى شاشة الهوم أو شاشة "مشاريعي"
        // Get.offAll(() => HomeScreen()); // مثال باستخدام GetX للانتقال للهوم
        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        ); // العودة للشاشة الأولى (الهوم عادة)
      }
    } catch (e) {
      // فشل
      if (mounted) {
        logger.e('Failed to send project request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: AppColors.error, // استخدام لون الخطأ من AppColors
          ),
        );
      }
    } finally {
      // Hide loading regardless of success or failure
      if (mounted) {
        setState(() {
          _isSubmittingRequest = false; // إخفاء التحميل
        });
      }
    }
  }

  // دالة بناء كرت المكتب المتجاوب
  Widget _buildOfficeCard(Office office, double cardWidth) {
    final bool isSelected = _selectedOffice == office;
    return GestureDetector(
      onTap: () => _onOfficeTapped(office),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: cardWidth,
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 0,
        ), // زيادة الهامش العمودي لتوسيع المسافة بين الكروت
        padding: const EdgeInsets.all(16), // زيادة Padding داخل الكرت
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.card, // لون خلفية الكرت بناءً على حالة الاختيار
          border: Border.all(
            color:
                isSelected
                    ? AppColors.accent
                    : Colors
                        .grey
                        .shade300, // حدود الكرت بناءً على حالة الاختيار
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(
                isSelected ? 0.2 : 0.1,
              ), // ظل أوضح عند الاختيار
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة المكتب مع حواف دائرية ومعالجة للأخطاء
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                office.imageUrl.isNotEmpty
                    ? (office.imageUrl.startsWith('http')
                        ? office.imageUrl
                        : '${Constants.baseUrl}/${office.imageUrl}') // استخدام Constants.baseUrl
                    : 'https://via.placeholder.com/80', // صورة افتراضية
                width: cardWidth * 0.15, // حجم نسبي للصورة ليتناسب مع عرض الكرت
                height: cardWidth * 0.15,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: cardWidth * 0.15,
                      height: cardWidth * 0.15,
                      color: AppColors.background, // لون خلفية للأيقونة
                      child: Icon(
                        Icons.business_rounded,
                        size: cardWidth * 0.1,
                        color: AppColors.textSecondary,
                      ), // أيقونة بديلة
                    ),
              ),
            ),
            const SizedBox(width: 16), // زيادة المسافة بين الصورة والنصوص
            // Expanded لضمان أن النصوص لا تتجاوز حدود الكرت
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المكتب
                  Text(
                    office.name,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 18 : 16, // حجم خط متجاوب
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // لون نص من AppColors
                    ),
                    maxLines: 2, // تحديد أقصى سطرين
                    overflow:
                        TextOverflow.ellipsis, // إضافة نقاط عند تجاوز السطرين
                  ),
                  const SizedBox(height: 6), // مسافة بين الاسم والموقع
                  // موقع المكتب
                  Text(
                    office.location,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 14 : 13, // حجم خط متجاوب
                      color:
                          AppColors.textSecondary, // لون نص ثانوي من AppColors
                    ),
                    maxLines: 1, // سطر واحد للموقع لتجنب الـ overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // مسافة بين الموقع والتقييم
                  // التقييم (نجمة + نص)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade700,
                        size: 18,
                      ), // أيقونة نجمة بلون أغمق
                      const SizedBox(width: 6),
                      Text(
                        office.rating.toStringAsFixed(
                          1,
                        ), // تنسيق الرقم العشري ليعرض منزلة عشرية واحدة
                        style: TextStyle(
                          fontSize: cardWidth > 400 ? 14 : 13, // حجم خط متجاوب
                          color:
                              AppColors
                                  .textSecondary, // لون نص ثانوي من AppColors
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // أيقونة الاختيار تظهر فقط عند اختيار المكتب
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 30,
              ), // أيقونة اختيار أوضح بلون من AppColors
            const SizedBox(width: 8), // مسافة للأيقونة
          ],
        ),
      ),
    );
  }

  // دالة بناء حالة "لا توجد نتائج" (متناسقة مع SearchScreen)
  Widget _buildNoResultsState(
    String message,
    VoidCallback onClearSearch,
    double cardWidth,
  ) {
    return Center(
      child: SingleChildScrollView(
        // لضمان التمرير على الشاشات الصغيرة إذا كان المحتوى كبيرًا
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة بديلة للمكاتب غير الموجودة (تم تصحيحها)
            Icon(
              Icons.business_center_outlined, // أيقونة موجودة في Material Icons
              size: 80,
              color: AppColors.primary, // أيقونة بلون من AppColors
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, // لون نص من AppColors
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms or refresh the list.',
              style: TextStyle(
                color: AppColors.textSecondary, // لون نص من AppColors
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // زر مسح البحث
            SizedBox(
              width: cardWidth * 0.6, // عرض الزر نسبيًا
              child: OutlinedButton(
                onPressed: onClearSearch,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.accent, // لون الحدود من AppColors
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppColors.accent, // لون النص من AppColors
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // زر تحديث قائمة المكاتب
            SizedBox(
              width: cardWidth * 0.6,
              child: ElevatedButton(
                onPressed: _loadOffices, // استدعاء دالة تحميل المكاتب
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // لون من AppColors
                  foregroundColor: AppColors.background, // لون من AppColors
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Refresh Offices',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ضبط عرض الكرت بناءً على حجم الشاشة (متجاوب)
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth =
        screenWidth > 600
            ? 600
            : screenWidth * 0.9; // أقصى عرض 600px أو 90% من عرض الشاشة

    return Scaffold(
      backgroundColor: AppColors.background, // خلفية الشاشة من AppColors
      // AppBar مخصص بتصميم ChooseOfficeScreen (تم تحسينه قليلاً)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0), // ارتفاع AppBar المخصص
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            40,
            16,
            20,
          ), // Padding أعلى لأزرار الحالة (Status bar)
          decoration: BoxDecoration(
            color: AppColors.primary, // لون خلفية AppBar من AppColors
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(
                  0.2,
                ), // ظل أغمق ليتناسق مع SearchScreen
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                color: AppColors.accent, // لون زر الرجوع من AppColors
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  "Choose an Office",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent, // لون العنوان من AppColors
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // توازن المساحة بسبب زر الرجوع
            ],
          ),
        ),
      ),
      body: Center(
        // توسيط المحتوى أفقياً
        child: ConstrainedBox(
          // تحديد عرض أقصى للمحتوى ليكون متجاوباً (Responsive)
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // أقصى عرض على الويب مثلاً
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ), // Padding جانبي للمحتوى
            child: Column(
              children: [
                const SizedBox(height: 16), // مسافة بعد الـ AppBar المخصص
                // حقل البحث
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search Office',
                    hintText: 'Search by name or location',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.accent, // لون أيقونة البحث من AppColors
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(
                          0.7,
                        ), // لون الحدود من AppColors
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            AppColors
                                .accent, // لون الحدود عند التركيز من AppColors
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.card, // لون خلفية الحقل من AppColors
                    labelStyle: TextStyle(
                      color:
                          AppColors
                              .textSecondary, // لون تسمية الحقل من AppColors
                    ),
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(
                        0.6,
                      ), // لون نص المساعدة من AppColors
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _onSearchChanged(''); // مسح حقل البحث
                              },
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),

                // عرض حالة التحميل أو قائمة المكاتب
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                          : _filteredOffices.isEmpty
                          ? _buildNoResultsState(
                            _searchQuery.isNotEmpty
                                ? 'No offices found matching "$_searchQuery"'
                                : 'No offices available.',
                            () => _onSearchChanged(
                              '',
                            ), // مسح البحث عند الضغط على الزر
                            cardWidth,
                          )
                          : ListView.builder(
                            itemCount: _filteredOffices.length,
                            itemBuilder: (context, index) {
                              final office = _filteredOffices[index];
                              return Center(
                                child: _buildOfficeCard(office, cardWidth),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 16),
                // زر "Next" أو "Select an office"
                ElevatedButton(
                  // زر معطل إذا لم يتم اختيار مكتب أو كان الطلب قيد الإرسال
                  onPressed:
                      _selectedOffice == null || _isSubmittingRequest
                          ? null
                          : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(
                      cardWidth,
                      50,
                    ), // عرض الزر بناءً على cardWidth
                    backgroundColor:
                        _selectedOffice != null && !_isSubmittingRequest
                            ? AppColors
                                .accent // لون الزر عند التفعيل من AppColors
                            : Colors.grey.shade400, // لون الزر عند التعطيل
                    foregroundColor: Colors.white, // لون نص الزر
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.accent.withOpacity(0.3), // ظل الزر
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isSubmittingRequest // عرض مؤشر تحميل إذا كان الطلب قيد الإرسال
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            _selectedOffice == null
                                ? 'Select an office to continue'
                                : 'Next',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 16), // مسافة في الأسفل
              ],
            ),
          ),
        ),
      ),
    );
  }
}
