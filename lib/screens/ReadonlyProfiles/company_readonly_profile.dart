// screens/profiles/company_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../models/Basic/company_model.dart';
import '../../models/Basic/project_model.dart';
import '../../models/Basic/review_model.dart';
import '../../services/ReadonlyProfiles/company_readonly.dart';
import '../../services/session.dart';
import 'project_readonly_profile.dart';
import '../../themes/app_colors.dart';
import 'package:logger/logger.dart';

class CompanyrProfileScreen extends StatefulWidget {
  final int companyId;
  final bool isOwner;
  const CompanyrProfileScreen({
    super.key,
    required this.companyId,
    this.isOwner = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CompanyrProfileScreenState createState() => _CompanyrProfileScreenState();
}

class _CompanyrProfileScreenState extends State<CompanyrProfileScreen> {
  final CompanyProfileService _profileService = CompanyProfileService();
  CompanyModel? _company;
  List<ProjectModel> _projects = [];
  List<Review> _reviews = [];
  final Logger logger = Logger();

  bool _isLoadingCompany = true;
  bool _isLoadingProjects = true;
  bool _isLoadingReviews = true;

  String? _companyError;
  String? _projectsError;
  String? _reviewsError;

  int? _currentUserId;
  bool _isActuallyOwner = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUserIdAndDetermineOwnership();
    _fetchAllData();
  }

  Future<void> _loadCurrentUserIdAndDetermineOwnership() async {
    _currentUserId = await Session.getUserId();
    _isActuallyOwner = widget.isOwner;
    if (mounted) setState(() {});
  }

  Future<void> _fetchAllData() async {
    _fetchCompanyDetails();
    _fetchCompanyProjects();
    _fetchCompanyReviews();
  }

  Future<void> _fetchCompanyDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingCompany = true);
    try {
      final companyData = await _profileService.getCompanyDetails(
        widget.companyId,
      );
      if (mounted) {
        setState(() {
          _company = companyData;
          _isLoadingCompany = false;
          _companyError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompany = false;
          _companyError = e.toString();
        });
      }
      logger.e(
        "Error fetching company details: $e",
      ); // تم التعليق لتقليل المخرجات في Console
    }
  }

  Future<void> _fetchCompanyProjects() async {
    if (!mounted) return;
    setState(() => _isLoadingProjects = true);
    try {
      final projectsData = await _profileService.getCompanyProjects(
        widget.companyId,
      );
      if (mounted) {
        setState(() {
          _projects = projectsData;
          _isLoadingProjects = false;
          _projectsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
          _projectsError = e.toString();
        });
      }
      logger.e(
        "Error fetching company projects: $e",
      ); // تم التعليق لتقليل المخرجات في Console
    }
  }

  Future<void> _fetchCompanyReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviewsData = await _profileService.getCompanyReviews(
        widget.companyId,
      );
      if (mounted) {
        setState(() {
          _reviews = reviewsData;
          _isLoadingReviews = false;
          _reviewsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
          _reviewsError = e.toString();
        });
      }
      logger.e(
        "Error fetching company reviews: $e",
      ); // تم التعليق لتقليل المخرجات في Console
    }
  }

  void _showAddReviewDialog() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a review.')),
      );
      return;
    }

    final TextEditingController commentController = TextEditingController();
    double ratingValue = 3.0;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card, // ****** تم إضافة لون الخلفية ******
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
          ), // ****** تم إضافة لون النص ******
          contentTextStyle: TextStyle(
            color: AppColors.textSecondary,
          ), // ****** تم إضافة لون النص ******
          title: const Text('Add Your Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RatingBar.builder(
                  initialRating: ratingValue,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder:
                      (context, _) => Icon(
                        Icons.star,
                        color: AppColors.accent,
                      ), // ****** تم استخدام AppColors.accent ******
                  onRatingUpdate: (rating) => ratingValue = rating,
                ),
                const SizedBox(height: 16),
                // ****** تم استبدال TextField العادي بـ _buildNeumorphicTextField ******
                _buildNeumorphicTextField(
                  controller: commentController,
                  hintText: 'Write your comment (optional)',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ), // ****** تم استخدام AppColors.accent ******
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors
                        .accent, // ****** تم استخدام AppColors.accent ******
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
              onPressed: () async {
                try {
                  await _profileService.addReview(
                    companyId: widget.companyId,
                    rating: ratingValue.toInt(),
                    comment:
                        commentController.text.trim().isEmpty
                            ? null
                            : commentController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                  _fetchCompanyReviews();
                  _fetchCompanyDetails(); // لتحديث متوسط التقييم
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to submit review: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ****** تم نقل دالة _buildNeumorphicTextField إلى هنا ******
  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.2),
            offset: const Offset(-3, -3),
            blurRadius: 5,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            offset: const Offset(3, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppColors.textSecondary),
        ),
        maxLines: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canEdit = _isActuallyOwner;

    return Scaffold(
      backgroundColor:
          AppColors.background, // ****** تم استخدام AppColors.background ******
      appBar: null, // تم إزالة الـ AppBar الافتراضي
      body: Column(
        // تم وضع كل المحتوى داخل Column لكي يمكن إضافة الرأسية في الأعلى
        children: [
          // الرأسية المخصصة
          Container(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            decoration: BoxDecoration(
              color:
                  AppColors
                      .primary, // ****** تم استخدام AppColors.primary ******
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
            child: SafeArea(
              // لضمان عدم تداخل المحتوى مع شريط الحالة في الأعلى
              bottom: false, // لا تضف مسافة بادئة من الأسفل
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 28,
                    ),
                    color:
                        AppColors
                            .accent, // ****** تم استخدام AppColors.accent ******
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      // استخدام اسم الشركة بدلاً من النص الثابت
                      _company?.name ?? 'Company Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            AppColors
                                .accent, // ****** تم استخدام AppColors.accent ******
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // نقل زر التعديل من الـ AppBar الأصلي إلى الرأسية المخصصة
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 28),
                      color:
                          AppColors
                              .accent, // ****** تم استخدام AppColors.accent ******
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edit profile functionality coming soon!',
                            ),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(
                      width: 48,
                    ), // توازن المساحة بسبب زر الرجوع إذا لم يكن زر التعديل موجودًا
                ],
              ),
            ),
          ),

          const SizedBox(height: 16), // المسافة بين الرأسية والمحتوى التالي
          // باقي محتوى الصفحة الأصلي، الآن داخل Expanded
          Expanded(
            child:
                (_isLoadingCompany && _company == null)
                    ? const Center(child: CircularProgressIndicator())
                    : (_companyError != null && _company == null)
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _companyError!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadInitialData,
                      child: ListView(
                        // ****** تعديل المسافة البادئة لتطابق OfficerProfileScreen ******
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          _buildCompanyInfoSection(),
                          const SizedBox(height: 24),
                          _buildProjectsSection(),
                          const SizedBox(height: 24),
                          _buildReviewsSection(),
                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      // ****** تم تطبيق نفس تنسيق النيومورفك لـ FAB ******
      floatingActionButton:
          _currentUserId != null && _company != null && !_isActuallyOwner
              ? Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.3),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.2),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.transparent, // اجعل الخلفية شفافة
                  foregroundColor: AppColors.accent, // لون النص والأيقونة
                  elevation: 0, // إزالة الظل الافتراضي
                  onPressed: _showAddReviewDialog,
                  label: const Text('Add Review'),
                  icon: const Icon(Icons.rate_review_outlined),
                ),
              )
              : null,
    );
  }

  Widget _buildCompanyInfoSection() {
    if (_company == null) return const SizedBox.shrink();

    return Container(
      // ****** تم تغيير Card إلى Container ******
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(
        24,
      ), // ****** تم توحيد المسافة البادئة ******
      decoration: BoxDecoration(
        color: AppColors.card, // ****** تم استخدام لون الخلفية ******
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(
              0.2,
            ), // ****** تم استخدام AppColors.shadow ******
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(
              0.1,
            ), // ****** تم استخدام AppColors.accent ******
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60, // ****** تم تكبير الحجم ******
                  backgroundImage:
                      (_company!.profileImage != null &&
                              _company!.profileImage!.isNotEmpty)
                          ? NetworkImage(_company!.profileImage!)
                          : null,
                  onBackgroundImageError:
                      (
                        _,
                        __,
                      ) {}, // ****** تم توحيد مع OfficerProfileScreen ******
                  child:
                      (_company!.profileImage == null ||
                              _company!.profileImage!.isEmpty)
                          ? Icon(
                            Icons.business_center,
                            size: 60, // ****** تم تكبير الحجم ******
                            color:
                                AppColors
                                    .accent, // ****** تم استخدام AppColors.accent ******
                          )
                          : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _company!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        AppColors
                            .textPrimary, // ****** تم استخدام AppColors.textPrimary ******
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_company!.rating != null && _company!.rating! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingBarIndicator(
                          rating: _company!.rating!,
                          itemBuilder:
                              (context, index) => Icon(
                                Icons.star,
                                color: AppColors.accent,
                              ), // ****** تم استخدام AppColors.accent ******
                          itemCount: 5,
                          itemSize: 22.0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_company!.rating!.toStringAsFixed(1)})',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color:
                                AppColors
                                    .textSecondary, // ****** تم استخدام AppColors.textSecondary ******
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_company!.companyType != null &&
                    _company!.companyType!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Chip(
                        label: Text(
                          _company!.companyType!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            AppColors
                                .accent, // ****** تم استخدام AppColors.accent ******
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          if (_company!.description != null &&
              _company!.description!.isNotEmpty)
            // ****** هنا التعديل: تم وضع Padding داخل Center ******
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _company!.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign:
                      TextAlign
                          .center, // ****** إضافة textAlign: TextAlign.center ******
                ),
              ),
            ),
          // ****** تم استخدام دالة _buildResponsiveInfoRow هنا بدلاً من _buildInfoRow ******
          if ((_company!.location != null && _company!.location!.isNotEmpty) ||
              (_company!.email != null && _company!.email!.isNotEmpty) ||
              (_company!.phone != null && _company!.phone!.isNotEmpty) ||
              (_company!.staffCount != null && _company!.staffCount! > 0))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: _buildResponsiveInfoRow([
                if (_company!.location != null &&
                    _company!.location!.isNotEmpty)
                  {
                    'icon': Icons.location_on_outlined,
                    'value': _company!.location!,
                  },
                if (_company!.email != null && _company!.email!.isNotEmpty)
                  {'icon': Icons.email_outlined, 'value': _company!.email!},
                if (_company!.phone != null && _company!.phone!.isNotEmpty)
                  {'icon': Icons.phone_outlined, 'value': _company!.phone!},
                if (_company!.staffCount != null && _company!.staffCount! > 0)
                  {
                    'icon': Icons.people_outline,
                    'value': _company!.staffCount.toString(),
                  },
              ]),
            ),
        ],
      ),
    );
  }

  // ****** تم نقل دالة _buildResponsiveInfoRow إلى هنا ******
  Widget _buildResponsiveInfoRow(List<Map<String, dynamic>> items) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final IconData icon = item['icon'];
      final String value = item['value'];

      if (value.isEmpty) continue;

      Widget row = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.accent,
          ), // ****** تم استخدام AppColors.accent ******
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ), // ****** تم استخدام AppColors.textSecondary ******
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

      widgets.add(row);

      // في وضع الويب فقط، أضف الفاصل
      if (!isMobile && i < items.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '|',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ), // ****** تم استخدام AppColors.textSecondary ******
          ),
        );
      }
    }

    if (isMobile) {
      // الموبايل: محاذاة لليسار
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    } else {
      // الويب: توسيط العناصر
      return Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: widgets),
      );
    }
  }

  // _buildProjectsSection تم تحديث الألوان وتغيير LayoutBuilder للتوحيد مع OfficerProfileScreen
  Widget _buildProjectsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Our Projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    AppColors
                        .textPrimary, // ****** تم استخدام AppColors.textPrimary ******
              ),
            ),
          ),
          if (_isLoadingProjects)
            const Center(child: CircularProgressIndicator())
          else if (_projectsError != null)
            Center(
              child: Text(
                _projectsError!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_projects.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No projects to display for this company.'),
              ),
            )
          else
            LayoutBuilder(
              // ****** تم استخدام LayoutBuilder ******
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  return SizedBox(
                    height: 250, // ****** تم تعديل الارتفاع ليتناسب ******
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return _buildProjectCard(project);
                      },
                    ),
                  );
                } else {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 بطاقات لكل صف
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4, // تناسب العرض والارتفاع
                        ),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      return _buildProjectCard(project);
                    },
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  // _buildProjectCard تم تحديث الألوان وتصحيح التنسيق
  Widget _buildProjectCard(ProjectModel project) {
    return Card(
      elevation: 2,
      color: AppColors.card, // ****** تم استخدام لون البطاقة ******
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProjectreadDetailsScreen(projectId: project.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:
                      AppColors
                          .textPrimary, // ****** تم استخدام AppColors.textPrimary ******
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (project.description != null &&
                  project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        AppColors
                            .textSecondary, // ****** تم استخدام AppColors.textSecondary ******
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor:
                        AppColors
                            .accent, // ****** تم استخدام AppColors.accent ******
                    label: Text(
                      project.status ?? 'N/A',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  if (project.endDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color:
                              AppColors
                                  .textSecondary, // ****** تم استخدام AppColors.textSecondary ******
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMd().format(project.endDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                AppColors
                                    .textSecondary, // ****** تم استخدام AppColors.textSecondary ******
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildReviewsSection تم تحديث الألوان وتنسيق المراجعات
  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Client Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    AppColors
                        .textPrimary, // ****** تم استخدام AppColors.textPrimary ******
              ),
            ),
          ),
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_reviewsError != null)
            Center(
              child: Text(
                _reviewsError!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_reviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No reviews yet for this company.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Container(
                  // ****** تم تغيير Card إلى Container وتطبيق الظلال ******
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.2),
                        offset: const Offset(-3, -3),
                        blurRadius: 5,
                      ),
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.1),
                        offset: const Offset(3, 3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.userName ?? 'Anonymous Client',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    AppColors
                                        .textPrimary, // ****** تم استخدام AppColors.textPrimary ******
                              ),
                            ),
                          ),
                          RatingBarIndicator(
                            rating: review.rating.toDouble(),
                            itemBuilder:
                                (context, _) => Icon(
                                  Icons.star,
                                  color: AppColors.accent,
                                ), // ****** تم استخدام AppColors.accent ******
                            itemCount: 5,
                            itemSize: 18.0,
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Text(
                            review.comment!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ), // ****** تم استخدام AppColors.textSecondary ******
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateFormat.yMMMd().format(review.reviewedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors
                                    .textSecondary, // ****** تم استخدام AppColors.textSecondary ******
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            ),
        ],
      ),
    );
  }
}
