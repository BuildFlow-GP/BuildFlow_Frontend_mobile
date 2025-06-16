/*

// screens/project_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لـ DateFormat
import '../../services/create/project_service.dart'; // أو اسم السيرفس الصحيح
import '../../models/userprojects/project_readonly_model.dart';
// import '../../models/office_model.dart';
// import '../../models/company_model.dart';
// import '../../models/user_model.dart';
import '../../utils/constants.dart'; // لمسار الصور
import '../../services/Basic/favorite_service.dart'; // لإضافة/إزالة المفضلة
import '../../services/session.dart'; // للتحقق من التوكن
// استيراد صفحات بروفايل المكتب والشركة للقراءة فقط (أو العادية)
// import 'office_readonly_profile.dart';
// import 'company_readonly_profile.dart';
// import 'ReadonlyProfiles/user_readonly_profile.dart'; // إذا كان لديك

class ProjectreadDetailsScreen extends StatefulWidget {
  final int projectId;

  const ProjectreadDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectreadDetailsScreen> createState() =>
      _ProjectreadDetailsScreenState();
}

class _ProjectreadDetailsScreenState extends State<ProjectreadDetailsScreen> {
  final ProjectService _projectService = ProjectService();
  final FavoriteService _favoriteService = FavoriteService();
  Future<ProjectreadonlyModel>? _projectDetailsFuture;
  bool _isFavorite = false; // حالة المفضلة للمشروع الحالي
  bool _isFavoriteLoading = true; // حالة تحميل المفضلة

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
    _checkIfFavorite(); // تحقق من حالة المفضلة
  }

  void _loadProjectDetails() {
    _projectDetailsFuture = _projectService.getProjectDetails(widget.projectId);
  }

  Future<void> _checkIfFavorite() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isFavoriteLoading = false);
      return; // لا يمكن التحقق من المفضلة بدون توكن
    }
    try {
      final favorites = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _isFavorite = favorites.any(
            (fav) =>
                fav.itemId == widget.projectId && fav.itemType == 'project',
          );
          _isFavoriteLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFavoriteLoading = false);
      print("Error checking if project is favorite: $e");
    }
  }

  Future<void> _toggleFavorite(ProjectreadonlyModel project) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to manage favorites.')),
        );
      }
      return;
    }

    setState(() => _isFavoriteLoading = true); // إظهار تحميل لزر المفضلة
    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(project.id, 'project');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${project.name} removed from favorites.')),
          );
        }
      } else {
        await _favoriteService.addFavorite(project.id, 'project');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${project.name} added to favorites.')),
          );
        }
      }
      // تحديث حالة الأيقونة بعد النجاح
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isFavoriteLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites: ${e.toString()}'),
          ),
        );
        setState(() => _isFavoriteLoading = false);
      }
      print("Error toggling favorite for project ${project.id}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: FutureBuilder<ProjectreadonlyModel>(
        future: _projectDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Project not found.'));
          } else {
            final project = snapshot.data!;
            return _buildProjectContent(project);
          }
        },
      ),
    );
  }

  Widget _buildProjectContent(ProjectreadonlyModel project) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    ); // عدلي حسب عملتك

    // DEBUG PRINTS
    debugPrint("Project ID: ${project.id}");
    debugPrint("Raw startDate from model: ${project.startDate}");
    debugPrint("Raw endDate from model: ${project.endDate}");
    debugPrint("Raw createdAt from model: ${project.createdAt}");

    if (project.startDate != null) {
      debugPrint("Type of startDate: ${project.startDate.runtimeType}");
    }
    if (project.endDate != null) {
      debugPrint("Type of endDate: ${project.endDate.runtimeType}");
    }
    debugPrint("Type of createdAt: ${project.createdAt.runtimeType}");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isFavoriteLoading) // فقط أظهر زر المفضلة إذا انتهى التحقق
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color:
                        _isFavorite
                            ? Colors.redAccent
                            : Theme.of(context).iconTheme.color,
                    size: 28,
                  ),
                  tooltip:
                      _isFavorite
                          ? 'Remove from Favorites'
                          : 'Add to Favorites',
                  onPressed: () => _toggleFavorite(project),
                )
              else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          _buildStatusChip(project.status),
          const SizedBox(height: 16.0),
          if (project.description != null && project.description!.isNotEmpty)
            Text(
              project.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

          const SizedBox(height: 20.0),
          _buildSectionTitle('Project Information'),
          _buildInfoRow(
            'Budget:',
            project.budget != null
                ? currencyFormat.format(project.budget)
                : 'N/A',
          ),
          _buildInfoRow(
            'Start Date:',
            project.startDate != null
                ? dateFormat.format(project.startDate!)
                : 'N/A',
          ),
          _buildInfoRow(
            'End Date:',
            project.endDate != null
                ? dateFormat.format(project.endDate!)
                : 'N/A',
          ),
          _buildInfoRow('Location:', project.location ?? 'N/A'),
          _buildInfoRow('Created On:', dateFormat.format(project.createdAt)),

          if (project.landLocation != null ||
              project.plotNumber != null ||
              project.basinNumber != null ||
              project.landArea != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Land Details'),
            if (project.landLocation != null)
              _buildInfoRow('Land Location:', project.landLocation!),
            if (project.plotNumber != null)
              _buildInfoRow('Plot Number:', project.plotNumber!),
            if (project.basinNumber != null)
              _buildInfoRow('Basin Number:', project.basinNumber!),
            if (project.landArea != null)
              _buildInfoRow('Land Area:', '${project.landArea} m²'),
          ],

          // معلومات المكتب المنفذ
          if (project.office != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Implementing Office'),
            _buildEntityCard(
              name: project.office!.name,
              imageUrl: project.office!.profileImage,
              typeLabel: project.office!.location, // مثال لعرض موقع المكتب
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder:
                //         (context) => OfficerReadOnlyProfileScreen(
                //           officeId: project.office!.id,
                //         ),
                //   ),
                // );
              },
            ),
          ],

          // معلومات الشركة المنفذة
          if (project.company != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Implementing Company'),
            _buildEntityCard(
              name: project.company!.name,
              imageUrl: project.company!.profileImage,
              typeLabel: project.company!.companyType, // مثال لعرض نوع الشركة
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder:
                //         (context) => CompanyReadOnlyProfileScreen(
                //           companyId: project.company!.id,
                //         ),
                //   ),
                // );
              },
            ),
          ],

          // معلومات مالك المشروع (إذا قررتِ عرضها)
          if (project.user != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Project Owner'),
            _buildEntityCard(
              name: project.user!.name,
              imageUrl: project.user!.profileImage,
              typeLabel: project.user!.email, // مثال لعرض إيميل المالك
              onTap: () {
                // يمكنكِ هنا الانتقال لبروفايل المستخدم إذا كان لديكِ شاشة لذلك
                // أو عدم جعلها قابلة للضغط
              },
            ),
          ],

          // روابط المستندات (إذا كانت عامة)
          if (project.document2D != null || project.document3D != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Project Documents'),
            if (project.document2D != null && project.document2D!.isNotEmpty)
              _buildDocumentLink("2D Documents", project.document2D!),
            if (project.document3D != null && project.document3D!.isNotEmpty)
              _buildDocumentLink("3D Model/Renders", project.document3D!),
          ],

          // يمكنكِ إضافة قسم للمراجعات هنا إذا أردتِ
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        iconData = Icons.hourglass_empty_rounded;
        break;
      case 'in progress':
      case 'inprogress':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        iconData = Icons.construction_rounded;
        break;
      case 'completed':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconData = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        iconData = Icons.help_outline_rounded;
    }
    return Chip(
      avatar: Icon(iconData, color: textColor, size: 18),
      label: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
    );
  }

  Widget _buildEntityCard({
    required String name,
    String? imageUrl,
    String? typeLabel,
    VoidCallback? onTap,
  }) {
    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(
        imageUrl.startsWith('http')
            ? imageUrl
            : '${Constants.baseUrl}/$imageUrl',
      ); // تأكدي من ApiConfig
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: imageProvider,
                onBackgroundImageError: (_, __) {},
                backgroundColor: Colors.grey.shade300,
                child:
                    imageProvider == null
                        ? const Icon(Icons.person, size: 28)
                        : null,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (typeLabel != null && typeLabel.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentLink(String title, String documentPath) {
    // في تطبيق حقيقي، ستستخدمين url_launcher لفتح الـ URL
    // import 'package:url_launcher/url_launcher.dart';
    // Future<void> _launchURL(String url) async {
    //   if (await canLaunchUrl(Uri.parse(url))) {
    //     await launchUrl(Uri.parse(url));
    //   } else {
    //     throw 'Could not launch $url';
    //   }
    // }
    String fullUrl =
        documentPath.startsWith('http')
            ? documentPath
            : '${Constants.baseUrl}/$documentPath';

    return ListTile(
      leading: const Icon(
        Icons.insert_drive_file_outlined,
        color: Colors.blueAccent,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () {
        print("Attempting to open document: $fullUrl");
        // _launchURL(fullUrl); // لإلغاء التعليق بعد إضافة url_launcher
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Link to: $fullUrl (url_launcher needed)")),
        );
      },
    );
  }
}
*/

// screens/project_details_screen.dart
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لـ DateFormat
import 'package:url_launcher/url_launcher.dart'; // لإطلاق الروابط
import '../../services/create/project_service.dart'; // أو اسم السيرفس الصحيح
import '../../models/userprojects/project_readonly_model.dart';
// import '../../models/office_model.dart';
// import '../../models/company_model.dart';
// import '../../models/user_model.dart';
import '../../utils/constants.dart'; // لمسار الصور
import '../../services/Basic/favorite_service.dart'; // لإضافة/إزالة المفضلة
import '../../services/session.dart'; // للتحقق من التوكن

// استيراد صفحات بروفايل المكتب والشركة للقراءة فقط (أو العادية)
// import 'office_readonly_profile.dart';
// import 'company_readonly_profile.dart';
// import 'ReadonlyProfiles/user_readonly_profile.dart'; // إذا كان لديك

class ProjectreadDetailsScreen extends StatefulWidget {
  final int projectId;

  const ProjectreadDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectreadDetailsScreen> createState() =>
      _ProjectreadDetailsScreenState();
}

class _ProjectreadDetailsScreenState extends State<ProjectreadDetailsScreen> {
  final ProjectService _projectService = ProjectService();
  final FavoriteService _favoriteService = FavoriteService();
  Future<ProjectreadonlyModel>? _projectDetailsFuture;
  bool _isFavorite = false; // حالة المفضلة للمشروع الحالي
  bool _isFavoriteLoading = true; // حالة تحميل المفضلة

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
    _checkIfFavorite(); // تحقق من حالة المفضلة
  }

  void _loadProjectDetails() {
    _projectDetailsFuture = _projectService.getProjectDetails(widget.projectId);
  }

  Future<void> _checkIfFavorite() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isFavoriteLoading = false);
      return; // لا يمكن التحقق من المفضلة بدون توكن
    }
    try {
      final favorites = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _isFavorite = favorites.any(
            (fav) =>
                fav.itemId == widget.projectId && fav.itemType == 'project',
          );
          _isFavoriteLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFavoriteLoading = false);
      print("Error checking if project is favorite: $e");
    }
  }

  Future<void> _toggleFavorite(ProjectreadonlyModel project) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to manage favorites.'),
            backgroundColor: AppColors.error, // استخدام لون الخطأ من AppColors
          ),
        );
      }
      return;
    }

    setState(() => _isFavoriteLoading = true); // إظهار تحميل لزر المفضلة
    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(project.id, 'project');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${project.name} removed from favorites.'),
              backgroundColor: AppColors.success, // لون النجاح من AppColors
            ),
          );
        }
      } else {
        await _favoriteService.addFavorite(project.id, 'project');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${project.name} added to favorites.'),
              backgroundColor: AppColors.success, // لون النجاح من AppColors
            ),
          );
        }
      }
      // تحديث حالة الأيقونة بعد النجاح
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isFavoriteLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites: ${e.toString()}'),
            backgroundColor: AppColors.error, // لون الخطأ من AppColors
          ),
        );
        setState(() => _isFavoriteLoading = false);
      }
      print("Error toggling favorite for project ${project.id}: $e");
    }
  }

  // دالة لمسح الروابط
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ); // فتح في تطبيق خارجي
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // لون الخلفية من AppColors
      appBar: AppBar(
        title: Text(
          'Project Details',
          style: TextStyle(
            color: AppColors.background,
          ), // لون النص في AppBar من AppColors
        ),
        backgroundColor: AppColors.accent, // لون AppBar من AppColors
        elevation: 0, // إزالة الظل من AppBar لمظهر أكثر حداثة
        iconTheme: IconThemeData(
          color: AppColors.background,
        ), // لون الأيقونات في AppBar من AppColors
      ),
      body: Center(
        // توسيط المحتوى أفقياً
        child: ConstrainedBox(
          // تحديد عرض أقصى للمحتوى ليكون متجاوباً (Responsive)
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // أقصى عرض على الويب مثلاً
          child: FutureBuilder<ProjectreadonlyModel>(
            future: _projectDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ), // لون من AppColors
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Loading project details...',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color:
                              AppColors
                                  .textSecondary, // لون نص التحميل من AppColors
                        ),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
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
                          'Failed to load project details.\n${snapshot.error}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: AppColors.error, // لون نص الخطأ من AppColors
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton.icon(
                          onPressed: _loadProjectDetails, // زر لإعادة المحاولة
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
                );
              } else if (!snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 60,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Project not found or no data available.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                final project = snapshot.data!;
                return _buildProjectContent(project);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProjectContent(ProjectreadonlyModel project) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    ); // عدلي حسب عملتك

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تحديث الجزء الخاص بالعنوان وزر المفضلة
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // توسيط عمودي
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 8.0,
                  ), // مسافة عن زر المفضلة
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // لون العنوان من AppColors
                    ),
                  ),
                ),
              ),
              // زر المفضلة مع مؤشر التحميل
              _isFavoriteLoading
                  ? SizedBox(
                    width: 32, // حجم أكبر قليلًا للمؤشر ليتناسق مع الأيقونة
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, // سمك المؤشر
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ), // لون من AppColors
                    ),
                  )
                  : IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isFavorite
                              ? Colors
                                  .redAccent // يمكن الاحتفاظ باللون الأحمر للمفضلة لتميزه
                              : AppColors.accent, // لون الأيقونة من AppColors
                      size: 30, // تكبير حجم الأيقونة
                    ),
                    tooltip:
                        _isFavorite
                            ? 'Remove from Favorites'
                            : 'Add to Favorites',
                    onPressed: () => _toggleFavorite(project),
                    splashRadius: 28, // حجم تأثير الضغط
                  ),
            ],
          ),
          const SizedBox(height: 10.0), // مسافة مناسبة بعد العنوان
          _buildStatusChip(project.status),
          const SizedBox(height: 20.0), // مسافة بعد الـ Chip

          if (project.description != null && project.description!.isNotEmpty)
            // استخدام Container لإعطاء الوصف خلفية خفيفة أو حدود
            Container(
              padding: const EdgeInsets.all(16.0), // padding أكبر
              decoration: BoxDecoration(
                color: AppColors.card, // لون خلفية البطاقة من AppColors
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  // إضافة ظل خفيف
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                project.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary, // لون النص من AppColors
                ),
                textAlign: TextAlign.justify, // محاذاة النص
              ),
            ),
          const SizedBox(height: 24.0), // زيادة المسافة بعد الوصف
          // قسم معلومات المشروع ضمن كرت
          _buildSectionTitle('Project Information'),
          Card(
            elevation: 2, // ظل خفيف للكرت
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // مسافة حول الكرت
            color: AppColors.card, // لون خلفية الكرت من AppColors
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding داخل الكرت
              child: Column(
                children: [
                  _buildInfoRow(
                    'Budget:',
                    project.budget != null
                        ? currencyFormat.format(project.budget)
                        : 'N/A',
                  ),
                  _buildInfoRow(
                    'Start Date:',
                    project.startDate != null
                        ? dateFormat.format(project.startDate!)
                        : 'N/A',
                  ),
                  _buildInfoRow(
                    'End Date:',
                    project.endDate != null
                        ? dateFormat.format(project.endDate!)
                        : 'N/A',
                  ),
                  _buildInfoRow('Location:', project.location ?? 'N/A'),
                  _buildInfoRow(
                    'Created On:',
                    dateFormat.format(project.createdAt),
                  ),
                ],
              ),
            ),
          ),

          // قسم تفاصيل الأرض ضمن كرت (إذا كانت موجودة)
          if (project.landLocation != null ||
              project.plotNumber != null ||
              project.basinNumber != null ||
              project.landArea != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Land Details'),
            Card(
              elevation: 2, // ظل خفيف للكرت
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
              ), // مسافة حول الكرت
              color: AppColors.card, // لون خلفية الكرت من AppColors
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding داخل الكرت
                child: Column(
                  children: [
                    if (project.landLocation != null)
                      _buildInfoRow('Land Location:', project.landLocation!),
                    if (project.plotNumber != null)
                      _buildInfoRow('Plot Number:', project.plotNumber!),
                    if (project.basinNumber != null)
                      _buildInfoRow('Basin Number:', project.basinNumber!),
                    if (project.landArea != null)
                      _buildInfoRow('Land Area:', '${project.landArea} m²'),
                  ],
                ),
              ),
            ),
          ],

          // معلومات المكتب المنفذ
          if (project.office != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Implementing Office'),
            _buildEntityCard(
              name: project.office!.name,
              imageUrl: project.office!.profileImage,
              typeLabel: project.office!.location, // مثال لعرض موقع المكتب
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder:
                //         (context) => OfficerReadOnlyProfileScreen(
                //           officeId: project.office!.id,
                //         ),
                //   ),
                // );
              },
            ),
          ],

          // معلومات الشركة المنفذة
          if (project.company != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Implementing Company'),
            _buildEntityCard(
              name: project.company!.name,
              imageUrl: project.company!.profileImage,
              typeLabel: project.company!.companyType, // مثال لعرض نوع الشركة
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder:
                //         (context) => CompanyReadOnlyProfileScreen(
                //           companyId: project.company!.id,
                //         ),
                //   ),
                // );
              },
            ),
          ],

          // معلومات مالك المشروع (إذا قررتِ عرضها)
          if (project.user != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Project Owner'),
            _buildEntityCard(
              name: project.user!.name,
              imageUrl: project.user!.profileImage,
              typeLabel: project.user!.email, // مثال لعرض إيميل المالك
              onTap: () {
                // يمكنكِ هنا الانتقال لبروفايل المستخدم إذا كان لديكِ شاشة لذلك
                // أو عدم جعلها قابلة للضغط
              },
            ),
          ],

          // روابط المستندات (إذا كانت عامة)
          if (project.document2D != null || project.document3D != null) ...[
            const SizedBox(height: 20.0),
            _buildSectionTitle('Project Documents'),
            if (project.document2D != null && project.document2D!.isNotEmpty)
              _buildDocumentLink("2D Documents", project.document2D!),
            if (project.document3D != null && project.document3D!.isNotEmpty)
              _buildDocumentLink("3D Model/Renders", project.document3D!),
          ],

          // يمكنكِ إضافة قسم للمراجعات هنا إذا أردتِ
          const SizedBox(height: 20.0), // مسافة نهائية
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 20.0), // مسافة أكبر
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700, // وزن خط أثقل
              color: AppColors.accent, // لون العنوان من AppColors
            ),
          ),
          const SizedBox(height: 6.0), // مسافة بين العنوان والفاصل
          // إضافة فاصل بصري تحت العنوان
          Divider(
            height: 1,
            thickness: 1.5,
            color: AppColors.primary.withOpacity(
              0.6,
            ), // لون الفاصل من AppColors
            indent: 0,
            endIndent: MediaQuery.of(context).size.width * 0.4, // فاصل أقصر
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // زيادة المسافة العمودية
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w600, // خط أثقل قليلًا للتسمية
              fontSize: 16, // حجم خط أكبر
              color: AppColors.textSecondary, // لون التسمية من AppColors
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // حجم خط أكبر
                color: AppColors.textPrimary, // لون القيمة من AppColors
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange.shade50; // درجة أفتح
        textColor = Colors.orange.shade700; // درجة أغمق
        iconData = Icons.hourglass_empty_rounded;
        break;
      case 'in progress':
      case 'inprogress':
        chipColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        iconData = Icons.construction_rounded;
        break;
      case 'completed':
        chipColor = AppColors.success.withOpacity(
          0.1,
        ); // لون من AppColors مع شفافية
        textColor = AppColors.success; // لون من AppColors
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'cancelled':
        chipColor = AppColors.error.withOpacity(
          0.1,
        ); // لون من AppColors مع شفافية
        textColor = AppColors.error; // لون من AppColors
        iconData = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = AppColors.textSecondary; // لون من AppColors
        iconData = Icons.help_outline_rounded;
    }
    return Chip(
      avatar: Icon(iconData, color: textColor, size: 20), // أيقونة أكبر قليلًا
      label: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600, // خط أثقل
          fontSize: 14,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 4.0,
      ), // توسيع الـ padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ), // حدود أكثر استدارة
    );
  }

  Widget _buildEntityCard({
    required String name,
    String? imageUrl,
    String? typeLabel,
    VoidCallback? onTap,
  }) {
    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(
        imageUrl.startsWith('http')
            ? imageUrl
            : '${Constants.baseUrl}/$imageUrl',
      );
    }

    return Card(
      elevation: 2.5, // ظل أوضح
      margin: const EdgeInsets.symmetric(vertical: 8.0), // مسافة أكبر
      color: AppColors.card, // لون خلفية الكرت من AppColors
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // استدارة أكبر للحدود
      ),
      clipBehavior: Clip.antiAlias, // لضمان قص المحتوى بشكل صحيح
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // padding أكبر
          child: Row(
            children: [
              // صورة البروفايل مع معالجة أفضل لحالة الخطأ/عدم وجودها
              CircleAvatar(
                radius: 30, // حجم أكبر للصورة
                backgroundColor: AppColors.background, // لون خلفية من AppColors
                foregroundImage: imageProvider,
                onForegroundImageError: (obj, stack) {
                  // يمكنك هنا تسجيل الخطأ أو عرض Placeholder مخصص
                  // print("Error loading image for $name: $obj");
                },
                child:
                    imageProvider == null
                        ? Icon(
                          Icons.person_rounded, // أيقونة شخص بتصميم أحدث
                          size: 36,
                          color:
                              AppColors
                                  .textSecondary, // لون الأيقونة من AppColors
                        )
                        : null,
              ),
              const SizedBox(width: 16.0), // مسافة أكبر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary, // لون النص من AppColors
                      ),
                    ),
                    if (typeLabel != null && typeLabel.isNotEmpty) ...[
                      const SizedBox(height: 4.0), // مسافة أكبر
                      Text(
                        typeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              AppColors
                                  .textSecondary, // لون النص الثانوي من AppColors
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ), // أيقونة أحدث وألوان من AppColors
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentLink(String title, String documentPath) {
    String fullUrl =
        documentPath.startsWith('http')
            ? documentPath
            : '${Constants.baseUrl}/$documentPath';

    return Card(
      // وضع الرابط داخل كرت ليعطيه بروزًا
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      color: AppColors.card, // لون خلفية الكرت من AppColors
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(
          Icons.cloud_download_rounded, // أيقونة تحميل أو وثيقة
          color: AppColors.accent, // لون من AppColors
          size: 28,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.accent, // لون النص من AppColors
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary, // لون خط التسطير من AppColors
          ),
        ),
        trailing: Icon(
          Icons.open_in_new_rounded,
          color: AppColors.textSecondary,
        ), // أيقونة لفتح الرابط
        onTap: () {
          print("Attempting to open document: $fullUrl");
          _launchURL(fullUrl);
        },
      ),
    );
  }
}
