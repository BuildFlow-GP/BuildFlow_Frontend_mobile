// screens/profiles/user_profile_screen.dart
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import '../../models/Basic/user_model.dart'; // تأكد من وجود هذا الموديل ومساره الصحيح
import '../../services/ReadonlyProfiles/user_readonly.dart'; // تأكد من وجود هذا السيرفس ومساره الصحيح
import '../../utils/constants.dart'; // استيراد Constants لمسار الصور، تأكد من وجوده إذا كنت تستخدمه

class UserrProfileScreen extends StatefulWidget {
  final int userId; // ID المستخدم الذي نريد عرض بروفايله

  const UserrProfileScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _UserrProfileScreenState createState() => _UserrProfileScreenState();
}

class _UserrProfileScreenState extends State<UserrProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userData = await _profileService.getUserDetails(widget.userId);
      if (mounted) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
      print("Error fetching user details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ضبط عرض المحتوى بناءً على حجم الشاشة (متجاوب)
    double screenWidth = MediaQuery.of(context).size.width;
    // أقصى عرض 600px في الشاشات الكبيرة، أو 90% من عرض الشاشة في الموبايل
    double contentMaxWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.background, // خلفية الشاشة من AppColors
      // AppBar مخصص بتصميم متناسق مع باقي الشاشات
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
                color: AppColors.shadow.withOpacity(0.2), // ظل أغمق
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
                  _user?.name ??
                      'User Profile', // عنوان الصفحة (اسم المستخدم أو "User Profile")
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
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth,
          ), // استخدام العرض المتجاوب
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ), // لون مؤشر التحميل من AppColors
                    ),
                  )
                  : _error != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 60,
                          ), // أيقونة خطأ بلون AppColors
                          const SizedBox(height: 16.0),
                          Text(
                            _error!,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color:
                                  AppColors.error, // لون نص الخطأ من AppColors
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton.icon(
                            onPressed: _fetchUserDetails, // زر لإعادة المحاولة
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.primary, // لون الزر من AppColors
                              foregroundColor:
                                  AppColors
                                      .background, // لون نص الزر من AppColors
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _user == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          color: AppColors.textSecondary,
                          size: 60,
                        ), // أيقونة "مستخدم غير موجود"
                        const SizedBox(height: 16.0),
                        Text(
                          'User data not available.',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color:
                                AppColors.textSecondary, // لون نص من AppColors
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    // للسماح بالسحب للتحديث
                    onRefresh: _fetchUserDetails,
                    child: ListView(
                      // استخدام ListView بدلاً من SingleChildScrollView
                      padding: const EdgeInsets.all(
                        16.0,
                      ), // Padding حول محتوى القائمة
                      children: [
                        _buildUserInfoSection(),
                        const SizedBox(height: 24),
                        // يمكنكِ إضافة أقسام أخرى هنا في المستقبل إذا أردتِ
                        // مثلاً: _buildUserProjectsSection()
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    if (_user == null) return const SizedBox.shrink();

    // تحديد تاريخ الانضمام وتنسيقه
    String memberSince = 'N/A';
    if (_user!.createdAt.isNotEmpty) {
      try {
        // إذا كان createdAt هو ISO 8601 string
        final DateTime joinedDate = DateTime.parse(_user!.createdAt);
        memberSince = DateFormat.yMMMd().format(joinedDate);
      } catch (e) {
        // إذا لم يكن بتنسيق ISO، اعرضه كما هو (أو قيمة افتراضية)
        memberSince = _user!.createdAt;
        print("Could not parse user createdAt date: ${_user!.createdAt}");
      }
    }

    // بناء مسار الصورة الكامل إذا كان لديك Constants.baseUrl
    String? profileImageUrl = _user!.profileImage;
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        !profileImageUrl.startsWith('http')) {
      profileImageUrl = '${Constants.baseUrl}/$profileImageUrl';
    }

    return Card(
      elevation: 4, // ظل أوضح للكرت
      color: AppColors.card, // لون خلفية الكرت من AppColors
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // توسيط المحتوى داخل الكرت
          children: [
            CircleAvatar(
              radius: 55, // حجم أكبر قليلًا
              backgroundColor:
                  AppColors.background, // لون خلفية الأفاتار من AppColors
              backgroundImage:
                  (profileImageUrl != null && profileImageUrl.isNotEmpty)
                      ? NetworkImage(profileImageUrl)
                      : null,
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading user profile image: $exception');
              },
              child:
                  (profileImageUrl == null || profileImageUrl.isEmpty)
                      ? Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: AppColors.textSecondary,
                      ) // أيقونة شخص بلون من AppColors
                      : null,
            ),
            const SizedBox(height: 20), // مسافة أكبر
            Text(
              _user!.name, // UserModel يضمن أنها لن تكون null (بسبب `?? ''`)
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // لون نص الاسم من AppColors
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Member since: $memberSince',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ), // لون نص ثانوي من AppColors
            ),
            const SizedBox(height: 24), // مسافة أكبر
            // **بداية التعديل لتوسيط Divider**
            Center(
              // توسيط Divider
              child: SizedBox(
                width:
                    MediaQuery.of(context).size.width *
                    0.5, // 50% من عرض الشاشة كحد أقصى للفاصل
                child: Divider(
                  color: AppColors.primary.withOpacity(0.6),
                  thickness: 1.5,
                ), // فاصل بلون من AppColors وسمك أكبر
              ),
            ),
            // **نهاية التعديل لتوسيط Divider**
            const SizedBox(height: 16), // مسافة بعد الفاصل
            // عرض المعلومات العامة فقط (تجنب الإيميل والهاتف والمعلومات البنكية هنا)
            // _buildInfoRow ليست بحاجة للتوسيط لأنها Row وتأخذ المساحة المتاحة ضمن Padding الكرت
            if (_user!.location != null && _user!.location!.isNotEmpty)
              _buildInfoRow(
                Icons.location_on_outlined,
                'Location',
                _user!.location!,
              ),
            /*
            // يمكنك إضافة حقل "نبذة" (bio/description) إذا كان موجوداً في UserModel
            if (_user!.bio != null &&
                _user!.bio!.isNotEmpty) // افتراض وجود حقل bio
              _buildInfoRow(Icons.info_outline_rounded, 'About', _user!.bio!),*/
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.accent,
          ), // أيقونة بحجم أكبر ولون من AppColors
          const SizedBox(width: 16), // مسافة أكبر
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, // لون نص التسمية من AppColors
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary, // لون نص القيمة من AppColors
              ),
            ),
          ),
        ],
      ),
    );
  }
}
