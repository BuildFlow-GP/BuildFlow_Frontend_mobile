/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/Basic/user_model.dart';
import '../../models/Basic/office_model.dart';
import '../../models/Basic/company_model.dart';
import '../../services/Basic/search_service.dart';
import '../ReadonlyProfiles/company_readonly_profile.dart';
import '../ReadonlyProfiles/office_readonly_profile.dart';
import '../ReadonlyProfiles/user_readonly_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();

  List<UserModel> users = [];
  List<OfficeModel> offices = [];
  List<CompanyModel> companies = [];

  late TabController _tabController;
  Timer? _debounce;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      performSearch();
    });
  }

  Future<void> performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => isLoading = true);

    try {
      users = await SearchService.searchUsers(query);
      offices = await SearchService.searchOffices(query);
      companies = await SearchService.searchCompanies(query);
    } catch (e) {
      logger.e('Search error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildUserCard(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.profileImage ?? ''),
        backgroundColor: Colors.grey[200],
      ),
      title: Text(user.name),
      onTap: () {
        // مثال على الانتقال
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserrProfileScreen(userId: user.id),
          ),
        );
        logger.i('Navigate to User ID: ${user.id}');
      },
    );
  }

  Widget buildOfficeCard(OfficeModel office) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(office.profileImage ?? ''),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(office.name),
        subtitle: Text(
          'Rating: ${office.rating?.toStringAsFixed(1) ?? 'N/A'} | ${office.location}',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      OfficerProfileScreen(officeId: office.id, isOwner: false),
            ),
          );

          print('Tapped on Office: ${office.name} (ID: ${office.id})');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to profile of ${office.name}')),
          );
          logger.i('Navigate to Office ID: ${office.id}');
        },
      ),
    );
  }

  Widget buildCompanyCard(CompanyModel company) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(company.profileImage ?? ''),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(company.name),
        subtitle: Text(
          'Rating: ${company.rating?.toStringAsFixed(1) ?? 'N/A'} | ${company.location}',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CompanyrProfileScreen(
                    companyId: company.id,
                    isOwner: false,
                  ),
            ),
          );

          logger.i('Navigate to Company ID: ${company.id}');
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade100,
        ),
        labelColor: Colors.blue[800],
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(text: 'Users'),
          Tab(text: 'Offices'),
          Tab(text: 'Companies'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTabBar(),
            const SizedBox(height: 10),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Users
                    ListView.builder(
                      itemCount: users.length,
                      itemBuilder:
                          (context, index) => buildUserCard(users[index]),
                    ),
                    // Offices
                    ListView.builder(
                      itemCount: offices.length,
                      itemBuilder:
                          (context, index) => buildOfficeCard(offices[index]),
                    ),
                    // Companies
                    ListView.builder(
                      itemCount: companies.length,
                      itemBuilder:
                          (context, index) =>
                              buildCompanyCard(companies[index]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}*/

// screens/search_screen.dart
import 'dart:async';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:buildflow_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/Basic/user_model.dart';
import '../../models/Basic/office_model.dart';
import '../../models/Basic/company_model.dart';
import '../../services/Basic/search_service.dart';
import '../ReadonlyProfiles/company_readonly_profile.dart';
import '../ReadonlyProfiles/office_readonly_profile.dart';
import '../ReadonlyProfiles/user_readonly_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final logger = Logger();

  List<UserModel> users = [];
  List<OfficeModel> offices = [];
  List<CompanyModel> companies = [];

  late TabController _tabController;
  Timer? _debounce;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    // يمكنك إجراء بحث مبدئي عند فتح الصفحة إذا أردت
    // performSearch();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // دالة تُستدعى عند تغيير نص البحث مع تأخير
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        performSearch();
      } else {
        // مسح النتائج إذا كان حقل البحث فارغًا
        setState(() {
          users = [];
          offices = [];
          companies = [];
        });
      }
    });
  }

  // دالة إجراء البحث الفعلي
  Future<void> performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return; // لا تقم بالبحث إذا كان الاستعلام فارغًا

    if (mounted) setState(() => isLoading = true);

    try {
      final fetchedUsers = await SearchService.searchUsers(query);
      final fetchedOffices = await SearchService.searchOffices(query);
      final fetchedCompanies = await SearchService.searchCompanies(query);

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          offices = fetchedOffices;
          companies = fetchedCompanies;
        });
      }
    } catch (e) {
      logger.e('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to perform search: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // دالة بناء كرت المستخدم
  Widget _buildUserCard(UserModel user, double cardWidth) {
    return _buildResultCard(
      name: user.name,
      imageUrl: user.profileImage,
      subtitle: user.email, // أو user.bio إذا كان متاحًا
      cardWidth: cardWidth,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserrProfileScreen(userId: user.id),
          ),
        );
        logger.i('Navigate to User ID: ${user.id}');
      },
    );
  }

  // دالة بناء كرت المكتب
  Widget _buildOfficeCard(OfficeModel office, double cardWidth) {
    return _buildResultCard(
      name: office.name,
      imageUrl: office.profileImage,
      subtitle:
          'Rating: ${office.rating?.toStringAsFixed(1) ?? 'N/A'} | ${office.location}',
      cardWidth: cardWidth,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    OfficerProfileScreen(officeId: office.id, isOwner: false),
          ),
        );
        logger.i('Navigate to Office ID: ${office.id}');
      },
    );
  }

  // دالة بناء كرت الشركة
  Widget _buildCompanyCard(CompanyModel company, double cardWidth) {
    return _buildResultCard(
      name: company.name,
      imageUrl: company.profileImage,
      subtitle:
          'Rating: ${company.rating?.toStringAsFixed(1) ?? 'N/A'} | ${company.location}',
      cardWidth: cardWidth,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CompanyrProfileScreen(
                  companyId: company.id,
                  isOwner: false,
                ),
          ),
        );
        logger.i('Navigate to Company ID: ${company.id}');
      },
    );
  }

  // دالة عامة لبناء كرت النتائج (للتناسق مع تصميم ChooseOfficeScreen)
  Widget _buildResultCard({
    required String name,
    String? imageUrl,
    String? subtitle,
    required double cardWidth,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl != null && imageUrl.isNotEmpty
                    ? (imageUrl.startsWith('http')
                        ? imageUrl
                        : '${Constants.baseUrl}/$imageUrl')
                    : 'https://via.placeholder.com/80', // صورة افتراضية
                width: cardWidth * 0.15, // حجم نسبي للصورة
                height: cardWidth * 0.15,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: cardWidth * 0.15,
                      height: cardWidth * 0.15,
                      color: AppColors.background,
                      child: Icon(
                        Icons.person_rounded,
                        size: cardWidth * 0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 18 : 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: cardWidth > 400 ? 14 : 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // دالة بناء الـ Tab Bar المخصص
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card, // خلفية التاب بار من AppColors
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary, // لون المؤشر من AppColors
        ),
        labelColor: AppColors.accent, // لون النص المختار
        unselectedLabelColor: AppColors.textSecondary, // لون النص غير المختار
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Users'),
          Tab(text: 'Offices'),
          Tab(text: 'Companies'),
        ],
      ),
    );
  }

  // دالة بناء حالة لا توجد نتائج
  Widget _buildNoResultsState(
    String message,
    VoidCallback onClearSearch,
    double cardWidth,
  ) {
    return Center(
      child: SingleChildScrollView(
        // لضمان التمرير على الشاشات الصغيرة إذا كان المحتوى كبيرًا
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
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
              'Try different search terms or clear the search.',
              style: TextStyle(
                color: AppColors.textSecondary, // لون نص من AppColors
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // حساب عرض الكرت المتجاوب
    double screenWidth = MediaQuery.of(context).size.width;
    // عرض أقصى 600px في الشاشات الكبيرة، أو 90% من عرض الشاشة في الموبايل
    double cardWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.background, // خلفية الشاشة من AppColors
      // AppBar مخصص بتصميم ChooseOfficeScreen
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
              Expanded(
                child: Text(
                  "Search", // عنوان الصفحة
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name, email, or location...',
                    hintText: 'Type to search...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.accent, // لون أيقونة البحث
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.7), // لون الحدود
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent, // لون الحدود عند التركيز
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.card, // لون خلفية الحقل
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary, // لون تسمية الحقل
                    ),
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(
                        0.6,
                      ), // لون نص المساعدة
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged(); // لتحديث النتائج
                              },
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTabBar(), // الـ Tab Bar المخصص
                const SizedBox(height: 16),
                if (isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // نتائج المستخدمين
                        users.isEmpty && _searchController.text.isNotEmpty
                            ? _buildNoResultsState(
                              'No users found matching "${_searchController.text}"',
                              () => _searchController.clear(),
                              cardWidth,
                            )
                            : users.isEmpty && _searchController.text.isEmpty
                            ? _buildNoResultsState(
                              'Start typing to search for users',
                              () => {},
                              cardWidth,
                            ) // رسالة مبدئية
                            : ListView.builder(
                              itemCount: users.length,
                              itemBuilder:
                                  (context, index) => Center(
                                    child: _buildUserCard(
                                      users[index],
                                      cardWidth,
                                    ),
                                  ),
                            ),
                        // نتائج المكاتب
                        offices.isEmpty && _searchController.text.isNotEmpty
                            ? _buildNoResultsState(
                              'No offices found matching "${_searchController.text}"',
                              () => _searchController.clear(),
                              cardWidth,
                            )
                            : offices.isEmpty && _searchController.text.isEmpty
                            ? _buildNoResultsState(
                              'Start typing to search for offices',
                              () => {},
                              cardWidth,
                            )
                            : ListView.builder(
                              itemCount: offices.length,
                              itemBuilder:
                                  (context, index) => Center(
                                    child: _buildOfficeCard(
                                      offices[index],
                                      cardWidth,
                                    ),
                                  ),
                            ),
                        // نتائج الشركات
                        companies.isEmpty && _searchController.text.isNotEmpty
                            ? _buildNoResultsState(
                              'No companies found matching "${_searchController.text}"',
                              () => _searchController.clear(),
                              cardWidth,
                            )
                            : companies.isEmpty &&
                                _searchController.text.isEmpty
                            ? _buildNoResultsState(
                              'Start typing to search for companies',
                              () => {},
                              cardWidth,
                            )
                            : ListView.builder(
                              itemCount: companies.length,
                              itemBuilder:
                                  (context, index) => Center(
                                    child: _buildCompanyCard(
                                      companies[index],
                                      cardWidth,
                                    ),
                                  ),
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
}
