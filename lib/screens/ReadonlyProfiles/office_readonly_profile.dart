import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../models/Basic/office_model.dart';
import '../../models/Basic/project_model.dart';
import '../../models/Basic/review_model.dart';
import '../../services/ReadonlyProfiles/office_readonly.dart';
import '../../services/session.dart';
import 'project_readonly_profile.dart';
import '../../themes/app_colors.dart'; // استيراد ألوانك

class OfficerProfileScreen extends StatefulWidget {
  final int officeId;
  final bool isOwner;

  const OfficerProfileScreen({
    super.key,
    required this.officeId,
    this.isOwner = false,
  });

  @override
  _OfficerProfileScreenState createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final OfficeProfileService _profileService = OfficeProfileService();
  OfficeModel? _office;
  List<ProjectModel> _projects = [];
  List<Review> _reviews = [];

  bool _isLoadingOffice = true;
  bool _isLoadingProjects = true;
  bool _isLoadingReviews = true;

  String? _officeError;
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
    _fetchOfficeDetails();
    _fetchOfficeProjects();
    _fetchOfficeReviews();
  }

  Future<void> _fetchOfficeDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingOffice = true);
    try {
      final officeData = await _profileService.getOfficeDetails(
        widget.officeId,
      );
      if (mounted) {
        setState(() {
          _office = officeData;
          _isLoadingOffice = false;
          _officeError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOffice = false;
          _officeError = e.toString();
        });
      }
    }
  }

  Future<void> _fetchOfficeProjects() async {
    if (!mounted) return;
    setState(() => _isLoadingProjects = true);
    try {
      final projectsData = await _profileService.getOfficeProjects(
        widget.officeId,
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
    }
  }

  Future<void> _fetchOfficeReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviewsData = await _profileService.getOfficeReviews(
        widget.officeId,
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
          backgroundColor: AppColors.card,
          titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          contentTextStyle: TextStyle(color: AppColors.textSecondary),
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
                      (context, _) => Icon(Icons.star, color: AppColors.accent),
                  onRatingUpdate: (rating) => ratingValue = rating,
                ),
                const SizedBox(height: 16),
                _buildNeumorphicTextField(
                  controller: commentController,
                  hintText: 'Write your comment (optional)',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
              onPressed: () async {
                try {
                  await _profileService.addReview(
                    officeId: widget.officeId,
                    rating: ratingValue.toInt(),
                    comment:
                        commentController.text.trim().isEmpty
                            ? null
                            : commentController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                  _fetchOfficeReviews();
                  _fetchOfficeDetails();
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
      backgroundColor: AppColors.background,
      appBar: null, // تم إزالة الـ AppBar الافتراضي
      body: Column(
        // تم وضع كل المحتوى داخل Column لكي يمكن إضافة الرأسية في الأعلى
        children: [
          // الرأسية المخصصة كما طلبت
          Container(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.primary, // استخدم اللون الرئيسي كما في المثال
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
                    color: AppColors.accent,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      // استخدام اسم المكتب بدلاً من النص الثابت
                      _office?.name ?? 'Office Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // نقل زر التعديل من الـ AppBar الأصلي إلى الرأسية المخصصة
                  if (canEdit)
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 28,
                      ), // يمكنك تعديل الحجم إذا لزم الأمر
                      color: AppColors.accent,
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
                (_isLoadingOffice && _office == null)
                    ? const Center(child: CircularProgressIndicator())
                    : (_officeError != null && _office == null)
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _officeError!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadInitialData,
                      child: ListView(
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          _buildOfficeInfoSection(),
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
      floatingActionButton:
          _currentUserId != null && _office != null && !_isActuallyOwner
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
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.accent,
                  elevation: 0,
                  onPressed: _showAddReviewDialog,
                  label: const Text('Add Review'),
                  icon: const Icon(Icons.rate_review_outlined),
                ),
              )
              : null,
    );
  }

  Widget _buildOfficeInfoSection() {
    if (_office == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.2),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
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
                  radius: 60,
                  backgroundImage:
                      (_office!.profileImage != null &&
                              _office!.profileImage!.isNotEmpty)
                          ? NetworkImage(_office!.profileImage!)
                          : null,
                  onBackgroundImageError: (_, __) {},
                  child:
                      (_office!.profileImage == null ||
                              _office!.profileImage!.isEmpty)
                          ? Icon(
                            Icons.business,
                            size: 60,
                            color: AppColors.accent,
                          )
                          : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _office!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_office!.rating != null && _office!.rating! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingBarIndicator(
                          rating: _office!.rating!,
                          itemBuilder:
                              (context, index) =>
                                  Icon(Icons.star, color: AppColors.accent),
                          itemCount: 5,
                          itemSize: 22.0,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_office!.rating!.toStringAsFixed(1)})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                // --- عرض البيانات الأفقية ---
                if ((_office!.location != null &&
                        _office!.location!.isNotEmpty) ||
                    (_office!.email != null && _office!.email!.isNotEmpty) ||
                    (_office!.phone != null && _office!.phone!.isNotEmpty) ||
                    (_office!.branches != null &&
                        _office!.branches!.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: _buildResponsiveInfoRow([
                      if (_office!.location != null &&
                          _office!.location!.isNotEmpty)
                        {
                          'icon': Icons.location_on_outlined,
                          'value': _office!.location!,
                        },
                      if (_office!.email != null && _office!.email!.isNotEmpty)
                        {
                          'icon': Icons.email_outlined,
                          'value': _office!.email!,
                        },
                      if (_office!.phone != null && _office!.phone!.isNotEmpty)
                        {
                          'icon': Icons.phone_outlined,
                          'value': _office!.phone!,
                        },
                      if (_office!.branches != null &&
                          _office!.branches!.isNotEmpty)
                        {
                          'icon': Icons.store_mall_directory_outlined,
                          'value': _office!.branches!,
                        },
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('|', style: TextStyle(fontSize: 16)),
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

  Widget _buildProjectsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Previous Projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                child: Text('No projects to display.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // تحديد عدد البطاقات المعروضة في الصف الواحد بناءً على عرض الشاشة
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  // عرض أفقية (مثل الموبايل)
                  return SizedBox(
                    height: 250,
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
                  // عرض شبكة (للكمبيوتر / الويب)
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

  Widget _buildProjectCard(ProjectModel project) {
    return Card(
      elevation: 2,
      color: AppColors.card,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor: AppColors.accent,
                    label: Text(
                      project.status ?? 'Unknown',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  if (project.endDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMd().format(project.endDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
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

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Ratings & Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                child: Text('No reviews yet for this office.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Container(
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
                              review.userName ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          RatingBarIndicator(
                            rating: review.rating.toDouble(),
                            itemBuilder:
                                (context, _) =>
                                    Icon(Icons.star, color: AppColors.accent),
                            itemCount: 5,
                            itemSize: 18.0,
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Text(review.comment!),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateFormat.yMMMd().format(review.reviewedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// screens/profiles/office_profile_screen.dart
/*import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../models/Basic/office_model.dart';
import '../../models/Basic/project_model.dart';
import '../../models/Basic/review_model.dart'; // استخدام ReviewModel الخاص بكِ
import '../../services/ReadonlyProfiles/office_readonly.dart';
import '../../services/session.dart';
import 'project_readonly_profile.dart';
// افترض أن UserModel موجود في المسار الصحيح
// import '../../models/user_model.dart';

class OfficerProfileScreen extends StatefulWidget {
  final int officeId;
  // isOwner يمكن تحديده ديناميكياً داخل الشاشة بناءً على Session.getUserId()
  // ومقارنته مع office.ownerId (إذا كان موجوداً في OfficeModel)
  // أو إذا كان officeId هو نفسه userId لمالك المكتب.
  // سأفترض حالياً أننا نمرره، ولكن يمكن تحسين هذا.
  final bool isOwner;

  const OfficerProfileScreen({
    super.key,
    required this.officeId,
    this.isOwner = false,
  });

  @override
  _OfficerProfileScreenState createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final OfficeProfileService _profileService = OfficeProfileService();
  OfficeModel? _office;
  List<ProjectModel> _projects = [];
  List<Review> _reviews = [];

  bool _isLoadingOffice = true;
  bool _isLoadingProjects = true;
  bool _isLoadingReviews = true;

  String? _officeError;
  String? _projectsError;
  String? _reviewsError;

  int? _currentUserId;
  bool _isActuallyOwner = false; // سيتم تحديده ديناميكياً

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUserIdAndDetermineOwnership(); // جلب المستخدم وتحديد الملكية أولاً
    _fetchAllData(); // ثم جلب باقي البيانات
  }

  Future<void> _loadCurrentUserIdAndDetermineOwnership() async {
    _currentUserId = await Session.getUserId();
    // تحديد الملكية هنا يتطلب معرفة كيف يتم ربط المكتب بالمالك
    // افترض أن OfficeModel يحتوي على حقل مثل `user_id` أو أن `office.id` هو نفسه `user_id` للمالك.
    // هذا الجزء يحتاج لتكييفه حسب هيكل بياناتك الدقيق.
    // للتوضيح، سأفترض أننا نعتمد على widget.isOwner حالياً، لكن يمكن تحسينه:
    // إذا كان `widget.isOwner` مرر كـ `true`، نثق به.
    // إذا لم يمرر أو كان `false`، وكان لدينا `_office.user_id == _currentUserId`، نعتبره مالكاً.
    _isActuallyOwner = widget.isOwner; // قيمة مبدئية
    if (mounted) setState(() {});
  }

  Future<void> _fetchAllData() async {
    _fetchOfficeDetails(); // ستقوم بتحديث _isActuallyOwner إذا لزم الأمر
    _fetchOfficeProjects();
    _fetchOfficeReviews();
  }

  Future<void> _fetchOfficeDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingOffice = true);
    try {
      final officeData = await _profileService.getOfficeDetails(
        widget.officeId,
      );
      if (mounted) {
        setState(() {
          _office = officeData;
          _isLoadingOffice = false;
          _officeError = null;
          // تحديث الملكية الفعلية بعد جلب بيانات المكتب
          // افترض أن OfficeModel لديه حقل `user_id` لمالك المكتب
          // أو أن office.id هو نفسه user_id للمالك (هذا أقل شيوعاً للمكاتب)
          // if (_currentUserId != null && officeData.userId == _currentUserId) { // مثال، عدلي officeData.userId
          //   _isActuallyOwner = true;
          // }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOffice = false;
          _officeError = e.toString();
        });
      }
      print("Error fetching office details: $e");
    }
  }

  Future<void> _fetchOfficeProjects() async {
    if (!mounted) return;
    setState(() => _isLoadingProjects = true);
    try {
      final projectsData = await _profileService.getOfficeProjects(
        widget.officeId,
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
      print("Error fetching office projects: $e");
    }
  }

  Future<void> _fetchOfficeReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviewsData = await _profileService.getOfficeReviews(
        widget.officeId,
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
      print("Error fetching office reviews: $e");
    }
  }

  void _showAddReviewDialog() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a review.')),
      );
      return;
    }
    // افترض أن _office.user_id هو ID المستخدم المالك للمكتب.
    // يجب أن يكون هذا الحقل موجوداً في OfficeModel إذا أردت هذا التحقق.
    // if (_office?.userId == _currentUserId) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('You cannot review your own office.')),
    //   );
    //   return;
    // }

    final TextEditingController commentController = TextEditingController();
    double ratingValue = 3.0;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
                      (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) => ratingValue = rating,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write your comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () async {
                // إضافة مؤشر تحميل هنا إذا أردت
                try {
                  await _profileService.addReview(
                    officeId: widget.officeId,
                    rating: ratingValue.toInt(),
                    comment:
                        commentController.text.trim().isEmpty
                            ? null
                            : commentController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                  _fetchOfficeReviews(); // تحديث قائمة المراجعات
                  _fetchOfficeDetails(); // تحديث تفاصيل المكتب (لتحديث متوسط التقييم)
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

  @override
  Widget build(BuildContext context) {
    // استخدام _isActuallyOwner للتحكم في زر التعديل
    final bool canEdit = _isActuallyOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(_office?.name ?? 'Office Profile'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => EditOfficeScreen(office: _office!)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile functionality coming soon!'),
                  ),
                );
              },
            ),
        ],
      ),
      body:
          (_isLoadingOffice && _office == null)
              ? const Center(child: CircularProgressIndicator())
              : (_officeError != null && _office == null)
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _officeError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadInitialData, // تحديث كل البيانات
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildOfficeInfoSection(),
                    const SizedBox(height: 24),
                    _buildProjectsSection(),
                    const SizedBox(height: 24),
                    _buildReviewsSection(),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
      floatingActionButton:
          _currentUserId != null &&
                  _office != null &&
                  !_isActuallyOwner // أظهر الزر فقط إذا لم يكن المالك
              ? FloatingActionButton.extended(
                onPressed: _showAddReviewDialog,
                label: const Text('Add Review'),
                icon: const Icon(Icons.rate_review_outlined),
              )
              : null, // لا تظهر الزر إذا كان المالك أو لم يتم تحميل بيانات المكتب
    );
  }

  Widget _buildOfficeInfoSection() {
    if (_office == null) {
      return const SizedBox.shrink(); // لا تعرض إذا لم يتم تحميل المكتب
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        (_office!.profileImage != null &&
                                _office!.profileImage!.isNotEmpty)
                            ? NetworkImage(_office!.profileImage!)
                            : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading office profile image: $exception');
                    },
                    child:
                        (_office!.profileImage == null ||
                                _office!.profileImage!.isEmpty)
                            ? const Icon(
                              Icons.business,
                              size: 50,
                            ) // أيقونة افتراضية
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _office!.name, // كان required في النموذج الأصلي
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_office!.rating != null && _office!.rating! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RatingBarIndicator(
                            rating: _office!.rating!,
                            itemBuilder:
                                (context, index) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 22.0,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_office!.rating!.toStringAsFixed(1)})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            if (_office!.location != null && _office!.location!.isNotEmpty)
              _buildInfoRow(
                Icons.location_on_outlined,
                'Location',
                _office!.location!,
              ),
            if (_office!.email != null && _office!.email!.isNotEmpty)
              _buildInfoRow(Icons.email_outlined, 'Email', _office!.email!),
            if (_office!.phone != null && _office!.phone!.isNotEmpty)
              _buildInfoRow(Icons.phone_outlined, 'Phone', _office!.phone!),
            if (_office!.branches != null && _office!.branches!.isNotEmpty)
              _buildInfoRow(
                Icons.store_mall_directory_outlined,
                'Branches',
                _office!.branches!,
              ),
            // يمكنك إضافة أي حقول أخرى هنا
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Previous Projects',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (_isLoadingProjects)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
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
              child: Text('No projects to display.'),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return SizedBox(
                  // تحديد عرض الكرت
                  width:
                      MediaQuery.of(context).size.width *
                      0.7, // 70% من عرض الشاشة
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped on ${project.name}')),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProjectreadDetailsScreen(
                                  projectId: project.id,
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    project.status ?? 'Unknown',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (project.endDate != null)
                                  Text(
                                    'Due: ${DateFormat.yMd().format(DateTime.parse(project.endDate!))}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Ratings & Reviews',
            style: Theme.of(context).textTheme.titleLarge,
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
              child: Text('No reviews yet for this office.'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              // بما أن ReviewModel الخاص بكِ يحتوي على userName، يمكننا استخدامه مباشرة
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // CircleAvatar( // افترض أن UserModel الخاص بالمراجع ليس لدينا صورته هنا مباشرة
                          //   child: Text(review.userName?.substring(0,1).toUpperCase() ?? "U"),
                          // ),
                          // const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review.userName ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          RatingBarIndicator(
                            rating: review.rating.toDouble(),
                            itemBuilder:
                                (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 18.0,
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                          child: Text(review.comment!),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateFormat.yMMMd().format(
                            review.reviewedAt,
                          ), // استخدام reviewedAt من ReviewModel
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          ),
      ],
    );
  }
}*/
