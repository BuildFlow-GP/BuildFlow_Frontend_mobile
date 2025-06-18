import 'package:buildflow_frontend/themes/app_colors.dart'; // تأكد من المسار الصحيح
import '../services/Basic/favorite_service.dart';
import 'ReadonlyProfiles/project_readonly_profile.dart';
import 'Basic/my_projects.dart';
import 'ReadonlyProfiles/office_readonly_profile.dart';
import 'ReadonlyProfiles/company_readonly_profile.dart';
import '../services/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/Basic/about_section.dart';
import '../widgets/Basic/contact_us.dart';
import 'Basic/type_of_project.dart';
import '../widgets/Navbar/navbar.dart';
import '../models/Basic/office_model.dart';
import '../models/Basic/company_model.dart';
import '../models/Basic/project_model.dart';
import '../services/Basic/suggestion_service.dart';
import '../widgets/suggestions/office_suggestion_card.dart';
import '../widgets/suggestions/company_suggestion_card.dart';
import '../widgets/suggestions/project_suggestion_card.dart';

// هذا السطر مجرد افتراض لمكتبة logger.
// إذا لم تكن تستخدم مكتبة 'logger'، يمكنك إزالة هذا السطر والسطر التالي،
// واستبدال جميع استخدامات 'logger.e' و 'logger.i' بـ 'print' أو 'Get.log'.
import 'package:logger/logger.dart';

final logger = Logger();

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
  String? _currentUserType; //  يتم تعيينه في initState

  // تعريف ScrollController لكل قسم - تم استرجاعه
  final Map<String, ScrollController> _scrollControllers = {
    'offices': ScrollController(),
    'companies': ScrollController(),
    'projects': ScrollController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _fetchCurrentUserType(); //  دالة لجلب نوع المستخدم
  }

  @override
  void dispose() {
    // التأكد من التخلص من الـ ScrollController لتجنب تسرب الذاكرة - تم استرجاعه
    _scrollControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchCurrentUserType() async {
    //  افترض أن Session.getUserType() هي async
    String? type = await Session.getUserType();
    if (mounted) {
      setState(() {
        _currentUserType = type;
      });
    }
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
        // إذا كانت logger غير معرفة، استبدلها بـ: print("Error during _fetchAllData: $e");
        logger.e("Error during _fetchAllData: $e");
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
          // إذا كانت logger غير معرفة، استبدلها بـ: print("Error fetching user favorites: $e");
          logger.e("Error fetching user favorites: $e");
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
          // إذا كانت logger غير معرفة، استبدلها بـ: print("Error fetching offices: $e");
          logger.e("Error fetching offices: $e");
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
          logger.e("Error fetching companies: $e");
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
          logger.e("Error fetching projects: $e");
        });
      }
    }
  }

  Widget _buildSuggestionSection<T>({
    required String title,
    required bool isLoadingSuggestions,
    required List<T> items,
    required Widget Function(T item) cardBuilder,
    required ScrollController scrollController, // تم استرجاع هذا البارامتر
    String? error,
  }) {
    final bool stillLoadingOverall =
        isLoadingSuggestions || _isLoadingFavorites;
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;

    // شرط جديد: هل هذا القسم هو "Suggested Projects"؟
    final bool isProjectSection = title.toLowerCase().contains("project");

    if (stillLoadingOverall) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error, fontSize: 16),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(
          child: Text(
            'No $title available at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    // دالة التمرير لليسار
    void scrollLeft() {
      final currentPosition = scrollController.offset;
      final targetPosition =
          currentPosition -
          (MediaQuery.of(context).size.width *
              0.7); // تمرير بنسبة 70% من عرض الشاشة
      scrollController.animateTo(
        targetPosition.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // دالة التمرير لليمين
    void scrollRight() {
      final currentPosition = scrollController.offset;
      final targetPosition =
          currentPosition +
          (MediaQuery.of(context).size.width *
              0.7); // تمرير بنسبة 70% من عرض الشاشة
      scrollController.animateTo(
        targetPosition.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 32.0,
            bottom: 12.0,
            right: 16.0,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accent, // اختر اللون المناسب لك
            ),
          ),
        ),
        SizedBox(
          height: 260, // ارتفاع ثابت لجميع أقسام المقترحات
          // هنا التغيير الرئيسي: استخدام Row لأزرار التحكم على الشاشات العريضة، ولكن ليس لقسم المشاريع
          child:
              isWideScreen && !isProjectSection
                  ? Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center, // لمحاذاة العناصر عمودياً في المنتصف
                    children: [
                      // السهم الأيسر
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                        child: AnimatedBuilder(
                          animation: scrollController,
                          builder: (context, child) {
                            final bool canScrollLeft =
                                scrollController.hasClients &&
                                scrollController.offset > 0;
                            return Opacity(
                              opacity:
                                  canScrollLeft
                                      ? 1.0
                                      : 0.4, // لجعل الزر باهتًا إذا لا يمكن التمرير
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 30,
                                  color: AppColors.accent,
                                ),
                                onPressed:
                                    canScrollLeft
                                        ? scrollLeft
                                        : null, // تعطيل الزر إذا لا يمكن التمرير
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.card.withOpacity(
                                    0.8,
                                  ),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // قائمة المقترحات (Expanded لتأخذ المساحة المتبقية)
                      Expanded(
                        child: ListView.builder(
                          controller:
                              scrollController, // ربط الـ ScrollController
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: cardBuilder(items[index]),
                              ),
                            );
                          },
                        ),
                      ),
                      // السهم الأيمن
                      // ... (الكود المحيط) ...
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                        child: AnimatedBuilder(
                          animation:
                              scrollController, //  نفترض أن scrollController معرف ومرفق بـ ListView
                          builder: (context, child) {
                            bool canScrollRight = false; //  قيمة افتراضية

                            //  ✅✅✅  التحقق الكامل قبل الوصول لـ position properties ✅✅✅
                            if (scrollController
                                    .hasClients && // هل الـ controller مرفق؟
                                scrollController
                                    .position
                                    .hasPixels && // هل تم حساب الـ offset الحالي؟
                                scrollController
                                    .position
                                    .hasContentDimensions) {
                              // هل أبعاد المحتوى والـ viewport معروفة؟

                              //  فقط إذا كانت الشروط أعلاه متحققة، يمكننا الوصول لـ maxScrollExtent و offset بأمان
                              //  استخدمي >= بدلاً من > إذا أردتِ إخفاء الزر عندما يكون المحتوى لا يتجاوز العرض تماماً
                              //  واستخدمي < بدلاً من <= إذا أردتِ إخفاء الزر عندما تصلين للنهاية تماماً
                              //  عادةً، scrollController.offset لا يصل بالضبط لـ maxScrollExtent بسبب الـ physics،
                              //  لذا قد تحتاجين لهامش صغير.
                              //  هنا، إذا كان الـ offset أصغر "قليلاً" من maxScrollExtent، نعتبر أنه يمكن التمرير.
                              //  يمكنكِ تعديل هذا الشرط ليناسب سلوك التمرير الذي تريدينه بدقة.
                              //  مثلاً، scrollController.position.maxScrollExtent - scrollController.offset > 1.0 (لتجنب مشاكل الدقة مع double)
                              if (scrollController.position.maxScrollExtent >
                                  0) {
                                // تأكدي أن هناك شيء للتمرير أصلاً
                                canScrollRight =
                                    scrollController.offset <
                                    (scrollController.position.maxScrollExtent -
                                        1.0); //  ناقص 1.0 كهامش بسيط
                              } else {
                                canScrollRight =
                                    false; //  إذا كان maxScrollExtent صفر أو أقل، لا يمكن التمرير
                              }
                            } else {
                              //  إذا لم تكن الشروط متحققة، الـ Scrollable لم يتم بناؤه أو فارغ.
                              //  logger.d("AnimatedBuilder: ScrollController position not fully initialized yet or no content.");
                              canScrollRight =
                                  false; //  نفترض أنه لا يمكن التمرير
                            }

                            return Opacity(
                              opacity:
                                  canScrollRight
                                      ? 1.0
                                      : 0.4, //  جعل الزر باهتاً إذا لا يمكن التمرير
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 30,
                                  color:
                                      AppColors
                                          .accent, //  تأكدي أن AppColors.accent معرف
                                ),
                                //  تعطيل الزر إذا لا يمكن التمرير (onPressed: null)
                                //  وإزالة تأثير الضغط إذا كان معطلاً
                                onPressed: canScrollRight ? scrollRight : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.card.withAlpha(
                                    (0.8 * 255).round(),
                                  ), //  استخدام withAlpha
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            );
                          },
                          // child: child, //  إذا كنتِ تستخدمين الـ child property لـ AnimatedBuilder
                        ),
                      ),
                      // ... (الكود المحيط) ...
                    ],
                  )
                  : ListView.builder(
                    // على الشاشات الصغيرة: ListView فقط بدون أسهم
                    // أو إذا كان قسم المشاريع (حتى على الشاشات العريضة)
                    controller:
                        scrollController, // يجب أن يكون هناك ScrollController دائماً
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: cardBuilder(items[index]),
                        ),
                      );
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
    final String itemFavoriteKey =
        "${itemType}_$itemId"; // تصحيح: يجب أن يكون مفتاح المفضلة صحيحًا
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
      logger.e("Error toggling favorite for $itemType $itemId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Navbar(),
            const SizedBox(height: 35.0),
            const AboutSection(),
            const SizedBox(height: 50.0),

            // Buttons (2 only)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final bool canStartNewProject =
                    _currentUserType?.toLowerCase() != "office";

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child:
                      isWide
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (canStartNewProject)
                                _QuickActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: "Start New Project",
                                  onTap:
                                      () => Get.to(
                                        () => const TypeOfProjectPage(),
                                      ),
                                ),
                              _QuickActionButton(
                                icon: Icons.work_outline,
                                label: "Previous Projects",
                                onTap:
                                    () =>
                                        Get.to(() => const MyProjectsScreen()),
                              ),
                            ],
                          )
                          : Column(
                            children: [
                              if (canStartNewProject)
                                _QuickActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: "Start New Project",
                                  onTap:
                                      () => Get.to(
                                        () => const TypeOfProjectPage(),
                                      ),
                                ),
                              const SizedBox(height: 12),
                              _QuickActionButton(
                                icon: Icons.work_outline,
                                label: "Previous Projects",
                                onTap:
                                    () =>
                                        Get.to(() => const MyProjectsScreen()),
                              ),
                            ],
                          ),
                );
              },
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
                    style: TextStyle(
                      color: AppColors.error,
                    ), // استخدام AppColors.error
                  ),
                ),
              ),
            const SizedBox(height: 80.0),
            _buildSuggestionSection<OfficeModel>(
              title: 'Offices',
              isLoadingSuggestions: _isLoadingOffices,
              items: _suggestedOffices,
              error: _officeError,
              scrollController:
                  _scrollControllers['offices']!, // تمرير الـ Controller
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
            const SizedBox(height: 60.0),
            _buildSuggestionSection<CompanyModel>(
              title: 'Companies',
              isLoadingSuggestions: _isLoadingCompanies,
              items: _suggestedCompanies,
              error: _companyError,
              scrollController:
                  _scrollControllers['companies']!, // تمرير الـ Controller
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
            const SizedBox(height: 60.0),
            _buildSuggestionSection<ProjectModel>(
              title: 'Projects',
              isLoadingSuggestions: _isLoadingProjects,
              items: _suggestedProjects,
              error: _projectError,
              scrollController:
                  _scrollControllers['projects']!, // تمرير الـ Controller
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
                    // إذا كانت logger غير معرفة، استبدلها بـ: print('Tapped on Project: ${project.name} (ID: ${project.id})');
                    logger.i(
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
            const SizedBox(height: 50.0),
            const ContactUsSection(),
            const SizedBox(height: 80.0),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool isHovering = false;

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            isHovering
                ? AppColors.primary
                : AppColors.accent, // استخدام AppColors
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow, // استخدام AppColors
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(widget.icon, size: isMobile ? 22 : 28),
        label: Text(
          widget.label,
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isHovering
                  ? AppColors.primary
                  : AppColors.accent, // استخدام AppColors
          foregroundColor:
              Colors
                  .white, // ألوانك (primary, accent) تتطلب نصًا أبيض لتباين جيد
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 32,
            vertical: isMobile ? 16 : 20,
          ),
          minimumSize: Size(isMobile ? double.infinity : 200, 55),
          maximumSize: Size(isMobile ? double.infinity : 300, 70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isHovering ? 12 : 4,
        ),
        onPressed: widget.onTap,
      ),
    );

    // على الموبايل ما في Hover، فنرجّع الزر فقط
    return isMobile
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: button,
        )
        : MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: button,
        );
  }
}
