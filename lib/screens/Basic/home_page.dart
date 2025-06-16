import 'dart:convert';

import 'package:buildflow_frontend/themes/app_colors.dart';

import '../../services/Basic/favorite_service.dart'; // تمت الإضافة
//import '../models/fav/detailed_fav_model.dart';
//import '../models/fav/userfav_model.dart'; // تمت الإضافة (افترض أن هذا هو اسم ملف الموديل)
import '../ReadonlyProfiles/project_readonly_profile.dart';
import 'favorite.dart';
import 'my_projects.dart';
import 'notifications_screen.dart';
import '../profiles/company_profile.dart';
import '../ReadonlyProfiles/office_readonly_profile.dart';
import '../ReadonlyProfiles/company_readonly_profile.dart';
// import 'ReadonlyProfiles/project_readonly_profile.dart'; // إذا كان لديك
import '../profiles/office_profile.dart';
import '../profiles/user_profile.dart'; // لبروفايل المستخدم
import '../../services/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/Basic/about_section.dart';
import '../../widgets/Basic/contact_us.dart';
import 'type_of_project.dart';
import '../../widgets/Navbar/navbar.dart';

import '../../models/Basic/office_model.dart';
import '../../models/Basic/company_model.dart';
import '../../models/Basic/project_model.dart';
import '../../services/Basic/suggestion_service.dart';
import '../../widgets/suggestions/office_suggestion_card.dart';
import '../../widgets/suggestions/company_suggestion_card.dart';
import '../../widgets/suggestions/project_suggestion_card.dart';
import 'search.dart';
// افترض أن لديك هذه الشاشات لبروفايلات القراءة فقط أو العادية
// تأكدي من المسارات الصحيحة
// import 'profiles/office_profile.dart' as OfficeOwnerProfile; // لتجنب التعارض إذا كانت الأسماء متشابهة
// import 'profiles/company_profile.dart' as CompanyOwnerProfile;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SuggestionService _suggestionService = SuggestionService();
  final FavoriteService _favoriteService =
      FavoriteService(); // إضافة سيرفس المفضلة

  List<OfficeModel> _suggestedOffices = [];
  List<CompanyModel> _suggestedCompanies = [];
  List<ProjectModel> _suggestedProjects = [];

  Set<String> _currentUserFavoriteIds =
      {}; // لتخزين معرفات المفضلة كـ "type_id"

  bool _isLoadingOffices = true;
  bool _isLoadingCompanies = true;
  bool _isLoadingProjects = true;
  bool _isLoadingFavorites = true; // حالة تحميل للمفضلة

  String? _officeError;
  String? _companyError;
  String? _projectError;
  String? _favoritesError;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    // يمكنك إظهار مؤشر تحميل عام إذا أردت
    // setState(() {
    //   _isLoadingOffices = true;
    //   _isLoadingCompanies = true;
    //   _isLoadingProjects = true;
    //   _isLoadingFavorites = true;
    // });

    // جلب المقترحات والمفضلة بشكل متوازٍ
    await Future.wait([
      _fetchSuggestions(),
      _fetchCurrentUserFavorites(),
      // ignore: body_might_complete_normally_catch_error
    ]).catchError((e) {
      // معالجة خطأ عام إذا فشل أحد الطلبات الرئيسية
      if (mounted) {
        print("Error during _fetchAllData: $e");
        // يمكنك ضبط رسالة خطأ عامة هنا
      }
    });
  }

  Future<void> _fetchCurrentUserFavorites() async {
    if (!mounted) return;
    setState(() => _isLoadingFavorites = true);
    try {
      // التحقق أولاً إذا كان المستخدم مسجلاً (لديه توكن)
      final token = await Session.getToken();
      if (token == null || token.isEmpty) {
        // لا يوجد توكن، لا يمكن جلب المفضلة، اعتبرها فارغة
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds = {};
            _isLoadingFavorites = false;
          });
        }
        return;
      }

      final favoriteItems = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _currentUserFavoriteIds =
              favoriteItems
                  .map((fav) => "${fav.itemType}_${fav.itemId}")
                  .toSet();
          _isLoadingFavorites = false;
          _favoritesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
          _favoritesError = "Failed to load favorites list."; // رسالة للمستخدم
          print("Error fetching user favorites: $e");
        });
      }
    }
  }

  Future<void> _fetchSuggestions() async {
    // جلب المكاتب
    try {
      final offices = await _suggestionService.getSuggestedOffices();
      if (mounted) {
        setState(() {
          _suggestedOffices = offices;
          _isLoadingOffices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOffices = false;
          _officeError = "Failed to load offices: ${e.toString()}";
          print("Error fetching offices: $e");
        });
      }
    }

    // جلب الشركات
    try {
      final companies = await _suggestionService.getSuggestedCompanies();
      if (mounted) {
        setState(() {
          _suggestedCompanies = companies;
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
          _companyError = "Failed to load companies: ${e.toString()}";
          print("Error fetching companies: $e");
        });
      }
    }

    // جلب المشاريع
    try {
      final projects = await _suggestionService.getSuggestedProjects();
      if (mounted) {
        setState(() {
          _suggestedProjects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
          _projectError = "Failed to load projects: ${e.toString()}";
          print("Error fetching projects: $e");
        });
      }
    }
  }

  Widget _buildSuggestionSection<T>({
    required String title,
    required bool isLoadingSuggestions, // تم تغيير الاسم ليكون أوضح
    required List<T> items,
    required Widget Function(T item) cardBuilder,
    String? error,
  }) {
    // يجب الانتظار حتى يتم تحميل كل من المقترحات والمفضلة (إذا كان المستخدم مسجلاً)
    // إذا كان المستخدم غير مسجل، _isLoadingFavorites ستكون false بسرعة
    final bool stillLoadingOverall =
        isLoadingSuggestions || _isLoadingFavorites;

    if (stillLoadingOverall) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(child: Text('No $title available at the moment.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 24.0,
            bottom: 8.0,
            right: 16.0,
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height:
              title.toLowerCase().contains("project")
                  ? 210
                  : 250, // تم تعديل ارتفاع المشروع قليلاً
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return cardBuilder(items[index]);
            },
          ),
        ),
      ],
    );
  }

  // دالة لمعالجة الضغط على زر المفضلة
  Future<void> _handleFavoriteToggle(
    String itemType,
    int itemId,
    String itemName,
    bool isCurrentlyFavorite,
  ) async {
    final String itemFavoriteKey = "${itemType}_$itemId";
    // التحقق من التوكن قبل محاولة التعديل
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to manage your favorites.'),
          ),
        );
        Get.to(
          () => /* SignInScreen() */ Placeholder(),
        ); // أو توجيهه لصفحة تسجيل الدخول
      }
      return;
    }

    // تجميد الـ UI قليلاً (اختياري)
    // setState(() => _isTogglingFavorite = true);

    try {
      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(itemId, itemType);
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds.remove(itemFavoriteKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName removed from favorites.')),
          );
        }
      } else {
        await _favoriteService.addFavorite(itemId, itemType);
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds.add(itemFavoriteKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName added to favorites.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update favorites for $itemName: ${e.toString()}',
            ),
          ),
        );
      }
      print("Error toggling favorite for $itemType $itemId: $e");
    } finally {
      // if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Navbar(),
            const AboutSection(),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              child: Wrap(
                // استخدام Wrap للأزرار
                alignment: WrapAlignment.center,
                spacing: 12.0,
                runSpacing: 8.0,
                children: [
                  ElevatedButton(
                    onPressed: () => Get.to(() => const TypeOfProjectPage()),
                    child: const Text("Start New Project"),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const NotificationsScreen()),
                    child: const Text("Notification"),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToProfile,
                    child: const Text("My Profile"),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const SearchScreen()),
                    child: const Text("Search"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final token = await Session.getToken();
                      if (token == null || token.isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please log in to view your favorites.',
                              ),
                            ),
                          );
                          // Get.to(() => SignInScreen());
                        }
                        return;
                      }
                      // الانتقال إلى شاشة المفضلة ثم تحديث قائمة المفضلة عند العودة
                      final result = await Get.to(
                        () => const FavoritesScreen(),
                      );
                      if (result == true || result == null) {
                        // إذا تم أي تغيير في المفضلة أو تم الإغلاق
                        _fetchCurrentUserFavorites();
                      }
                    },
                    child: const Text("Favorites"),
                  ),

                  // ... (الكود السابق للأزرار الأخرى) ...
                  OutlinedButton(
                    onPressed: () async {
                      //  <--  (1) جعل الدالة async
                      //  (2) التحقق من التوكن قبل الانتقال
                      final token = await Session.getToken();
                      if (token == null || token.isEmpty) {
                        if (mounted) {
                          //  (3) التأكد أن الويدجت ما زال mounted
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please log in to view your projects.',
                              ),
                            ),
                          );
                          // يمكنكِ توجيه المستخدم لصفحة تسجيل الدخول إذا أردتِ
                          // Get.to(() => SignInScreen());
                        }
                        return; // الخروج من الدالة إذا لم يكن هناك توكن
                      }

                      // (4) الانتقال إلى شاشة MyProjectsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProjectsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      // هذا الجزء يبقى كما هو إذا كان موجوداً
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "My Previous Projects",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  // ... (الكود اللاحق) ...,
                ],
              ),
            ),

            if (_favoritesError != null &&
                _isLoadingFavorites == false) // عرض خطأ تحميل المفضلة إذا حدث
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Center(
                  child: Text(
                    _favoritesError!,
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ),

            _buildSuggestionSection<OfficeModel>(
              title: 'Suggested Offices',
              isLoadingSuggestions: _isLoadingOffices,
              items: _suggestedOffices,
              error: _officeError,
              cardBuilder: (office) {
                final String officeFavoriteKey = "office_${office.id}";
                bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                  officeFavoriteKey,
                );
                return OfficeSuggestionCard(
                  office: office,
                  isFavorite: isCurrentlyFavorite, // تمرير الحالة
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                OfficerProfileScreen(officeId: office.id),
                      ),
                    );
                  },
                  onFavoriteToggle:
                      () => _handleFavoriteToggle(
                        'office',
                        office.id,
                        office.name,
                        isCurrentlyFavorite,
                      ),
                );
              },
            ),

            _buildSuggestionSection<CompanyModel>(
              title: 'Suggested Companies',
              isLoadingSuggestions: _isLoadingCompanies,
              items: _suggestedCompanies,
              error: _companyError,
              cardBuilder: (company) {
                final String companyFavoriteKey = "company_${company.id}";
                bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                  companyFavoriteKey,
                );
                return CompanySuggestionCard(
                  company: company,
                  isFavorite: isCurrentlyFavorite, // تمرير الحالة
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CompanyrProfileScreen(companyId: company.id),
                      ),
                    );
                  },
                  onFavoriteToggle:
                      () => _handleFavoriteToggle(
                        'company',
                        company.id,
                        company.name,
                        isCurrentlyFavorite,
                      ),
                );
              },
            ),

            _buildSuggestionSection<ProjectModel>(
              title: 'Suggested Projects',
              isLoadingSuggestions: _isLoadingProjects,
              items: _suggestedProjects,
              error: _projectError,
              cardBuilder: (project) {
                final String projectFavoriteKey = "project_${project.id}";
                bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                  projectFavoriteKey,
                );
                return ProjectSuggestionCard(
                  project: project,
                  isFavorite: isCurrentlyFavorite, // تمرير الحالة
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProjectreadDetailsScreen(projectId: project.id),
                      ),
                    );
                    print(
                      'Tapped on Project: ${project.name} (ID: ${project.id})',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigate to details of ${project.name}'),
                      ),
                    );
                  },
                  onFavoriteToggle:
                      () => _handleFavoriteToggle(
                        'project',
                        project.id,
                        project.name,
                        isCurrentlyFavorite,
                      ),
                );
              },
            ),

            const ContactUsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() async {
    final token = await Session.getToken();
    if (token == null) {
      debugPrint("No token found, user likely not logged in.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to view your profile.")),
        );
      }
      return;
    }
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint("Invalid token format");
        return;
      }
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = json.decode(payload);
      final userType = data['userType']?.toString();
      final int id = data['id'] as int; // افترض أن id دائماً موجود وهو int

      if (!mounted) return;
      if (userType == null) {
        debugPrint('Token data is incomplete: userType or id is null');
        return;
      }

      Widget? profilePage;
      switch (userType.toLowerCase()) {
        case 'individual':
          // تأكدي أن UserProfileScreen تقبل isOwner أو userId
          profilePage = UserProfileScreen(isOwner: true /* userId: id */);
          break;
        case 'company':
          // تأكدي أن CompanyProfileScreen تقبل isOwner و companyId
          profilePage = CompanyProfileScreen(isOwner: true, companyId: id);
          break;
        case 'office':
          // تأكدي أن OfficerProfileScreen (أو OfficeProfileScreen) تقبل isOwner و officeId
          profilePage = OfficeProfileScreen(isOwner: true, officeId: id);
          break;
        default:
          debugPrint("Unknown userType: $userType");
      }
      if (profilePage != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profilePage!),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No profile page for type: $userType")),
        );
      }
    } catch (e) {
      debugPrint("Error parsing token or navigating in _navigateToProfile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error accessing your profile.")),
        );
      }
    }
  }
}

/*
// lib/screens/home_screen.dart

import 'dart:convert';
import 'package:buildflow_frontend/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // لتجنب الأخطاء إذا كنت تستخدم GetX في أماكن أخرى

// استيراد الخدمات والموديلات
import '../services/favorite_service.dart';
import '../services/session.dart';
import '../services/suggestion_service.dart';
import '../models/Basic/office_model.dart';
import '../models/Basic/company_model.dart';
import '../models/Basic/project_model.dart';

// استيراد الويدجتات المساعدة
import '../widgets/about_section.dart';
import '../widgets/contact_us.dart';
import '../widgets/navbar.dart';
import '../widgets/suggestions/office_suggestion_card.dart';
import '../widgets/suggestions/company_suggestion_card.dart';
import '../widgets/suggestions/project_suggestion_card.dart';

// استيراد شاشات التطبيق المختلفة (الآن ستكون محتوى يتم وضعه في IndexedStack)
// تأكد من أن هذه الملفات موجودة وأنها لا تحتوي على Scaffold و BottomNavigationBar خاص بها
import 'profiles/user_profile.dart'; // UserProfileScreen
import 'search.dart'; // SearchScreen
import 'favorite.dart'; // FavoritesScreen (اسم الملف كان favorite.dart)

// استيراد الشاشات التي تفتح بشكل منفصل (ليست جزءًا من BottomNav)
import 'Design/type_of_project.dart'; // TypeOfProjectPage
import 'my_projects.dart'; // MyProjectsScreen

// استيراد شاشات البروفايلات للقراءة فقط أو الخاصة بالمالكين (تفتح بـ Navigator.push)
import 'ReadonlyProfiles/project_readonly_profile.dart';
import 'profiles/company_profile.dart'; // CompanyProfileScreen (للمالك)
import 'ReadonlyProfiles/office_readonly_profile.dart'; // OfficerProfileScreen (للقراءة فقط)
import 'ReadonlyProfiles/company_readonly_profile.dart'; // CompanyrProfileScreen (للقراءة فقط)
import 'profiles/office_profile.dart'; // OfficeProfileScreen (للمالك)

// استيراد Widgets التنقل الجديدة
import '../widgets/custom_bottom_nav.dart';
import '../widgets/base_screen_layout.dart'; // لتغليف الصفحات ووضع Navbar

// HomeScreen ستكون الآن هي الحاوية الرئيسية للتطبيق التي تدير التنقل بالأسفل
class HomeScreen extends StatefulWidget {
  final bool isOwner; // تمرير قيمة isOwner من main.dart
  const HomeScreen({this.isOwner = false, super.key}); // قيمة افتراضية

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // خدمات جلب البيانات
  final SuggestionService _suggestionService = SuggestionService();
  final FavoriteService _favoriteService = FavoriteService();

  // قوائم البيانات المقترحة
  List<OfficeModel> _suggestedOffices = [];
  List<CompanyModel> _suggestedCompanies = [];
  List<ProjectModel> _suggestedProjects = [];

  // مجموعة لتخزين معرفات المفضلة الحالية للمستخدم (كـ "type_id")
  Set<String> _currentUserFavoriteIds = {};

  // حالات التحميل لكل قسم
  bool _isLoadingOffices = true;
  bool _isLoadingCompanies = true;
  bool _isLoadingProjects = true;
  bool _isLoadingFavorites = true; // حالة تحميل للمفضلة

  // رسائل الخطأ لكل قسم
  String? _officeError;
  String? _companyError;
  String? _projectError;
  String? _favoritesError;

  // -------------------------------------------------------------
  // منطق التنقل السفلي
  // المؤشر للصفحة المختارة في شريط التنقل السفلي
  int _selectedIndex = 0; // تبدأ من الصفحة الرئيسية (index 0)

  // متغير لحمل الـ Widget الخاص بصفحة البروفايل بناءً على نوع المستخدم
  Widget? _currentProfileWidget;

  // قائمة Widgets التي ستمثل كل صفحة من صفحات التطبيق (التابات)
  late final List<Widget> _widgetOptions;

  // دالة تُستدعى عند النقر على أيقونة في شريط التنقل السفلي
  void _onBottomNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // إذا تم النقر على أيقونة المفضلة (index 2) وتحتاج لتحديث فوري
      if (index == 2) {
        _fetchCurrentUserFavorites(); // إعادة تحميل قائمة المفضلة
      }
      // إذا تم النقر على أيقونة البروفايل (index 4)، قم بتحميل البروفايل الصحيح
      if (index == 4 && _currentProfileWidget == null) {
        _loadProfileContentForTab();
      }
    });
  }
  // -------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // تهيئة قائمة الصفحات (التابات)
    // لاحظ: تاب البروفايل (index 4) سيستخدم _currentProfileWidget
    _widgetOptions = <Widget>[
      // الصفحة الرئيسية (index 0)
      BaseScreenLayout(child: _buildHomePageContent(context)),
      // صفحة البحث (index 1)
      const BaseScreenLayout(child: SearchScreen()),
      // صفحة المفضلة (index 2)
      const BaseScreenLayout(child: FavoritesScreen()),
      // صفحة الإشعارات (index 3) - يجب التأكد من وجود NotificationsScreen
      const BaseScreenLayout(child: ChatScreen()),
      // صفحة البروفايل (index 4) - ستعرض المحتوى الذي تحدده _currentProfileWidget
      // سنضع مؤشر تحميل افتراضي أو رسالة حتى يتم تحميل البروفايل الفعلي
      BaseScreenLayout(
        child:
            _currentProfileWidget ??
            const Center(child: CircularProgressIndicator()),
      ),
    ];

    // جلب جميع البيانات عند تهيئة الشاشة الرئيسية
    _fetchAllData();

    // إذا كانت الصفحة الافتراضية هي البروفايل (مثلاً، إذا بدأ التطبيق من هنا)
    // يمكن استدعاء _loadProfileContentForTab() هنا أيضاً
    if (_selectedIndex == 4) {
      _loadProfileContentForTab();
    }
  }

  // دالة لجلب جميع البيانات (مقترحات ومفضلة) بشكل متوازٍ
  Future<void> _fetchAllData() async {
    if (!mounted) return;
    print("Fetching all data...");
    setState(() {
      _isLoadingOffices = true;
      _isLoadingCompanies = true;
      _isLoadingProjects = true;
      _isLoadingFavorites = true;
    });

    await Future.wait([
      _fetchSuggestions(),
      _fetchCurrentUserFavorites(),
    ]).catchError((e) {
      if (mounted) {
        print("Error during _fetchAllData: $e");
      }
    });

    if (mounted) {
      setState(() {}); // لتحديث الواجهة بعد انتهاء التحميلات
    }
    print("All data fetch attempts completed.");
  }

  // دالة لجلب قائمة المفضلة الحالية للمستخدم
  Future<void> _fetchCurrentUserFavorites() async {
    if (!mounted) return;
    setState(() => _isLoadingFavorites = true);
    print("Fetching current user favorites...");
    try {
      final token = await Session.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds = {};
            _isLoadingFavorites = false;
            _favoritesError = null;
          });
        }
        print("No token found for favorites, returning.");
        return;
      }

      final favoriteItems = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _currentUserFavoriteIds =
              favoriteItems
                  .map((fav) => "${fav.itemType}_${fav.itemId}")
                  .toSet();
          _isLoadingFavorites = false;
          _favoritesError = null;
        });
        print(
          "Favorites fetched successfully. Count: ${_currentUserFavoriteIds.length}",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
          _favoritesError = "Failed to load favorites list.";
          print("Error fetching user favorites: $e");
        });
      }
    }
  }

  // دالة لجلب المقترحات (مكاتب، شركات، مشاريع)
  Future<void> _fetchSuggestions() async {
    if (!mounted) return;
    print("Fetching suggestions...");

    try {
      final offices = await _suggestionService.getSuggestedOffices();
      if (mounted) {
        setState(() {
          _suggestedOffices = offices;
          _isLoadingOffices = false;
        });
        print("Offices fetched successfully. Count: ${offices.length}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOffices = false;
          _officeError = "Failed to load offices: ${e.toString()}";
          print("Error fetching offices: $e");
        });
      }
    }

    try {
      final companies = await _suggestionService.getSuggestedCompanies();
      if (mounted) {
        setState(() {
          _suggestedCompanies = companies;
          _isLoadingCompanies = false;
        });
        print("Companies fetched successfully. Count: ${companies.length}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
          _companyError = "Failed to load companies: ${e.toString()}";
          print("Error fetching companies: $e");
        });
      }
    }

    try {
      final projects = await _suggestionService.getSuggestedProjects();
      if (mounted) {
        setState(() {
          _suggestedProjects = projects;
          _isLoadingProjects = false;
        });
        print("Projects fetched successfully. Count: ${projects.length}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
          _projectError = "Failed to load projects: ${e.toString()}";
          print("Error fetching projects: $e");
        });
      }
    }
    print("Suggestions fetch attempts completed.");
  }

  // دالة مساعدة لبناء قسم المقترحات بشكل عام
  Widget _buildSuggestionSection<T>({
    required String title,
    required bool isLoadingSuggestions,
    required List<T> items,
    required Widget Function(T item) cardBuilder,
    String? error,
  }) {
    final bool stillLoadingOverall =
        isLoadingSuggestions || _isLoadingFavorites;

    print(
      "Building $title: isLoadingSuggestions=$isLoadingSuggestions, _isLoadingFavorites=$_isLoadingFavorites, stillLoadingOverall=$stillLoadingOverall",
    );

    if (stillLoadingOverall) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(child: Text('No $title available at the moment.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 24.0,
            bottom: 8.0,
            right: 16.0,
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: title.toLowerCase().contains("project") ? 210 : 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return cardBuilder(items[index]);
            },
          ),
        ),
      ],
    );
  }

  // دالة لمعالجة الضغط على زر المفضلة (إضافة/إزالة)
  Future<void> _handleFavoriteToggle(
    String itemType,
    int itemId,
    String itemName,
    bool isCurrentlyFavorite,
  ) async {
    final String itemFavoriteKey = "${itemType}_$itemId";
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to manage your favorites.'),
          ),
        );
      }
      return;
    }

    try {
      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(itemId, itemType);
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds.remove(itemFavoriteKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName removed from favorites.')),
          );
        }
      } else {
        await _favoriteService.addFavorite(itemId, itemType);
        if (mounted) {
          setState(() {
            _currentUserFavoriteIds.add(itemFavoriteKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName added to favorites.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update favorites for $itemName: ${e.toString()}',
            ),
          ),
        );
      }
      print("Error toggling favorite for $itemType $itemId: $e");
    }
  }

  // دالة _loadProfileContentForTab: تقوم بتحليل التوكن وتحديث _currentProfileWidget
  Future<void> _loadProfileContentForTab() async {
    if (!mounted) return;
    setState(() {
      // إظهار مؤشر تحميل داخل التاب أثناء جلب بيانات البروفايل
      _currentProfileWidget = const Center(child: CircularProgressIndicator());
    });

    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      debugPrint("No token found, user likely not logged in for profile tab.");
      if (mounted) {
        setState(() {
          _currentProfileWidget = const Center(
            child: Text(
              "Please log in to view your profile.",
              style: TextStyle(color: Colors.black),
            ),
          );
        });
      }
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint("Invalid token format for profile tab");
        if (mounted) {
          setState(() {
            _currentProfileWidget = const Center(
              child: Text(
                "Error: Invalid profile data.",
                style: TextStyle(color: Colors.red),
              ),
            );
          });
        }
        return;
      }
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = json.decode(payload);
      final userType = data['userType']?.toString();
      final int id = data['id'] as int; // افترض أن id دائماً موجود وهو int

      if (!mounted) return;
      if (userType == null) {
        debugPrint(
          'Token data is incomplete: userType or id is null for profile tab',
        );
        if (mounted) {
          setState(() {
            _currentProfileWidget = const Center(
              child: Text(
                "Error: Incomplete profile data.",
                style: TextStyle(color: Colors.red),
              ),
            );
          });
        }
        return;
      }

      Widget? profilePage;
      switch (userType.toLowerCase()) {
        case 'individual':
          profilePage = UserProfileScreen(isOwner: widget.isOwner);
          break;
        case 'company':
          profilePage = CompanyProfileScreen(
            isOwner: widget.isOwner,
            companyId: id,
          );
          break;
        case 'office':
          profilePage = OfficeProfileScreen(
            isOwner: widget.isOwner,
            officeId: id,
          );
          break;
        default:
          debugPrint("Unknown userType for profile tab: $userType");
          profilePage = Center(
            child: Text(
              "No specific profile page for type: $userType",
              style: const TextStyle(color: Colors.orange),
            ),
          );
      }

      if (mounted) {
        setState(() {
          _currentProfileWidget = profilePage;
        });
      }
    } catch (e) {
      debugPrint("Error parsing token or loading profile for tab: $e");
      if (mounted) {
        setState(() {
          _currentProfileWidget = const Center(
            child: Text(
              "Error loading your profile. Please try again.",
              style: TextStyle(color: Colors.red),
            ),
          );
        });
      }
    }
  }

  // دالة بناء محتوى الصفحة الرئيسية (الأزرار، الأقسام المقترحة، الاتصال بنا)
  // هذه الدالة تم فصلها لتكون محتوى التاب الأول (Home)
  Widget _buildHomePageContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navbar تمت إزالته من هنا، وسيتم إضافته بواسطة BaseScreenLayout
          const AboutSection(),

          // قسم الأزرار
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const TypeOfProjectPage(), // يفتح صفحة جديدة منفصلة
                        ),
                      ),
                  child: const Text("Start New Project"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // "My Profile": هذا الزر سيقوم بتغيير التاب إلى صفحة البروفايل (index 4)
                    // وسيتم استدعاء _loadProfileContentForTab() تلقائيا عند تبديل التاب
                    _onBottomNavItemTapped(4);
                  },
                  child: const Text("My Profile"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // "Search": هذا الزر سيقوم بتغيير التاب إلى صفحة البحث (index 1)
                    _onBottomNavItemTapped(1);
                  },
                  child: const Text("Search"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final token = await Session.getToken();
                    if (token == null || token.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please log in to view your favorites.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    // "Favorites": هذا الزر سيقوم بتغيير التاب إلى صفحة المفضلة (index 2)
                    _onBottomNavItemTapped(2);
                    // يمكنك إعادة تحميل المفضلة هنا لضمان تحديث البيانات بعد الانتقال إلى التاب
                    _fetchCurrentUserFavorites();
                  },
                  child: const Text("Favorites"),
                ),

                OutlinedButton(
                  onPressed: () async {
                    final token = await Session.getToken();
                    if (token == null || token.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please log in to view your projects.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyProjectsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "My Previous Projects",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // عرض خطأ تحميل المفضلة إذا حدث
          if (_favoritesError != null && _isLoadingFavorites == false)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Center(
                child: Text(
                  _favoritesError!,
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            ),

          // قسم المقترحات للمكاتب
          _buildSuggestionSection<OfficeModel>(
            title: 'Suggested Offices',
            isLoadingSuggestions: _isLoadingOffices,
            items: _suggestedOffices,
            error: _officeError,
            cardBuilder: (office) {
              final String officeFavoriteKey = "office_${office.id}";
              bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                officeFavoriteKey,
              );
              return OfficeSuggestionCard(
                office: office,
                isFavorite: isCurrentlyFavorite,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              OfficerProfileScreen(officeId: office.id),
                    ),
                  );
                },
                onFavoriteToggle:
                    () => _handleFavoriteToggle(
                      'office',
                      office.id,
                      office.name,
                      isCurrentlyFavorite,
                    ),
              );
            },
          ),

          // قسم المقترحات للشركات
          _buildSuggestionSection<CompanyModel>(
            title: 'Suggested Companies',
            isLoadingSuggestions: _isLoadingCompanies,
            items: _suggestedCompanies,
            error: _companyError,
            cardBuilder: (company) {
              final String companyFavoriteKey = "company_${company.id}";
              bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                companyFavoriteKey,
              );
              return CompanySuggestionCard(
                company: company,
                isFavorite: isCurrentlyFavorite,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              CompanyrProfileScreen(companyId: company.id),
                    ),
                  );
                },
                onFavoriteToggle:
                    () => _handleFavoriteToggle(
                      'company',
                      company.id,
                      company.name,
                      isCurrentlyFavorite,
                    ),
              );
            },
          ),

          // قسم المقترحات للمشاريع
          _buildSuggestionSection<ProjectModel>(
            title: 'Suggested Projects',
            isLoadingSuggestions: _isLoadingProjects,
            items: _suggestedProjects,
            error: _projectError,
            cardBuilder: (project) {
              final String projectFavoriteKey = "project_${project.id}";
              bool isCurrentlyFavorite = _currentUserFavoriteIds.contains(
                projectFavoriteKey,
              );
              return ProjectSuggestionCard(
                project: project,
                isFavorite: isCurrentlyFavorite,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ProjectreadDetailsScreen(projectId: project.id),
                    ),
                  );
                  print(
                    'Tapped on Project: ${project.name} (ID: ${project.id})',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigate to details of ${project.name}'),
                    ),
                  );
                },
                onFavoriteToggle:
                    () => _handleFavoriteToggle(
                      'project',
                      project.id,
                      project.name,
                      isCurrentlyFavorite,
                    ),
              );
            },
          ),

          const ContactUsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // هذا هو الـ `build` الرئيسي لـ `HomeScreen` الذي سيعرض `Scaffold` وشريط التنقل
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }
}

// **أمثلة على الشاشات الأخرى التي يجب أن تكون موجودة في مجلداتها الخاصة:**
// إذا لم تكن هذه الملفات موجودة لديك، قم بإنشائها لتجنب الأخطاء
// تأكد أيضاً أنها لا تحتوي على Scaffold أو BottomNavigationBar خاص بها
// وأنها ملفوفة بـ BaseScreenLayout عندما يتم استخدامها (كما هو الحال في _widgetOptions)

// lib/screens/search_screen.dart
// class SearchScreen extends StatelessWidget {
//   const SearchScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Search Screen Content', style: TextStyle(fontSize: 24, color: Colors.black)));
//   }
// }

// lib/screens/favorite.dart (أو favorites_screen.dart)
// class FavoritesScreen extends StatelessWidget {
//   const FavoritesScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Favorites Screen Content', style: TextStyle(fontSize: 24, color: Colors.black)));
//   }
// }

// lib/screens/notifications_screen.dart
// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Notifications Screen Content', style: TextStyle(fontSize: 24, color: Colors.black)));
//   }
// }

// lib/screens/my_projects.dart
// class MyProjectsScreen extends StatelessWidget {
//   const MyProjectsScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const BaseScreenLayout(
//       child: Center(child: Text('My Projects Screen Content', style: TextStyle(fontSize: 24, color: Colors.black))),
//     );
//   }
// }

// lib/screens/Design/type_of_project.dart
// class TypeOfProjectPage extends StatelessWidget {
//   const TypeOfProjectPage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const BaseScreenLayout(
//       child: Center(child: Text('Type of Project Page Content', style: TextStyle(fontSize: 24, color: Colors.black))),
//     );
//   }
// }

// تذكر تعديل main.dart لتشغيل HomeScreen*/
