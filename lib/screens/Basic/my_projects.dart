// screens/Basic/my_projects.dart
import 'package:buildflow_frontend/services/session.dart' show Session;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../services/create/project_service.dart';
import '../../models/Basic/project_model.dart';

import '../Design/my_project_details.dart';
import '../super/project_details_super.dart'; // ✅✅✅ استيراد شاشة الإشراف
import 'package:buildflow_frontend/themes/app_colors.dart';

final Logger logger = Logger(printer: PrettyPrinter(methodCount: 1));

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  final ProjectService _projectService = ProjectService();

  Future<List<ProjectModel>>? _designProjectsFuture;
  Future<List<ProjectModel>>? _supervisionProjectsFuture;
  String? _sessionUserType;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);
    _designProjectsFuture = null; // مسح الـ Futures عند إعادة التهيئة
    _supervisionProjectsFuture = null;
    try {
      _sessionUserType = await Session.getUserType();
      if (!mounted) return;
      if (_sessionUserType == null) {
        throw Exception("User type not found in session.");
      }

      await _loadProjectsBasedOnType(); //  دالة واحدة للتحميل
    } catch (e) {
      logger.e("Error in _initializeData", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error initializing screen: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  // ✅ NEW: دالة موحدة لتحميل كل المشاريع
  Future<void> _loadProjectsBasedOnType() async {
    if (_sessionUserType == null || !mounted) return;

    //  تعيين الـ Futures
    if (_sessionUserType!.toLowerCase() == 'office') {
      _designProjectsFuture =
          _projectService
              .getAssignedOfficeProjects(); // ترجع List<ProjectModel>
      _supervisionProjectsFuture =
          _projectService
              .getAssignedOfficeSupervisionProjects(); // ترجع List<ProjectModel>
    } else if (_sessionUserType!.toLowerCase() == 'individual') {
      _designProjectsFuture =
          _projectService.getMyProjectsp(); // ترجع List<ProjectModel>
      _supervisionProjectsFuture =
          _projectService.getMySupervisionProjects(); // ترجع List<ProjectModel>
    } else if (_sessionUserType!.toLowerCase() == 'company') {
      _designProjectsFuture = Future.value([]); // الشركة لا تعرض مشاريع تصميم
      _supervisionProjectsFuture =
          _projectService
              .getAssignedCompanySupervisionProjects(); // ترجع List<ProjectModel>
    } else {
      _designProjectsFuture = Future.error(
        Exception("Unknown user type for design projects: $_sessionUserType"),
      );
      _supervisionProjectsFuture = Future.error(
        Exception(
          "Unknown user type for supervision projects: $_sessionUserType",
        ),
      );
    }
    // استدعاء setState لإعادة بناء الـ FutureBuilders
    if (mounted) setState(() {});
  }

  Future<void> _refreshAllProjects() async {
    logger.i("Refreshing ALL projects for user type: $_sessionUserType");
    await _initializeData(); //  تستدعي التحميل من جديد
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double contentMaxWidth = screenWidth > 1200 ? 1200 : screenWidth;
    int crossAxisCount =
        (screenWidth >= 1024)
            ? 3
            : (screenWidth >= 768)
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        /* ... AppBar كما هو ... */
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2),
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
                color: AppColors.accent,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Previous Projects',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  color: AppColors.accent,
                  tooltip: 'Refresh Projects',
                  onPressed: _isInitializing ? null : _refreshAllProjects,
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          _isInitializing //  مؤشر تحميل عام أثناء جلب نوع المستخدم والـ Futures الأولية
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: ListView(
                    padding: const EdgeInsets.only(
                      bottom: 20,
                    ), //  إضافة padding سفلي
                    children: [
                      if (_designProjectsFuture != null &&
                          _sessionUserType?.toLowerCase() != 'company')
                        _buildProjectSection(
                          title: "Design Projects",
                          projectsFuture: _designProjectsFuture!,
                          crossAxisCount: crossAxisCount,
                          isSupervisionProject: false,
                        ),

                      if (_supervisionProjectsFuture != null) ...[
                        if (_sessionUserType?.toLowerCase() !=
                            'company') //  لا تعرض فاصل إذا كانت الشركة تعرض قسم إشراف فقط
                          const Divider(
                            height: 30,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                        _buildProjectSection(
                          title: "Supervision Projects",
                          projectsFuture: _supervisionProjectsFuture!,
                          crossAxisCount: crossAxisCount,
                          isSupervisionProject: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  // ✅ MODIFIED: الـ Future الآن يتوقع List<ProjectModel>
  Widget _buildProjectSection({
    required String title,
    required Future<List<ProjectModel>> projectsFuture, //  تم تغيير النوع هنا
    required int crossAxisCount,
    required bool isSupervisionProject,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        FutureBuilder<List<ProjectModel>>(
          //  تم تغيير النوع هنا
          future: projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                heightFactor: 3,
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    'No projects found in this category.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            } else {
              final List<ProjectModel> projects =
                  snapshot.data!; //  النوع الآن ProjectModel
              // لا حاجة للتحويل داخل itemBuilder بعد الآن
              return crossAxisCount > 1
                  ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio:
                          1.25, //  تعديل بسيط لنسبة العرض للارتفاع
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectItemCard(
                        projects[index],
                        isSupervisionProject: isSupervisionProject,
                      );
                    },
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildProjectItemCard(
                          projects[index],
                          isSupervisionProject: isSupervisionProject,
                        ),
                      );
                    },
                  );
            }
          },
        ),
      ],
    );
  }

  Widget _buildProjectItemCard(
    ProjectModel project, {
    required bool isSupervisionProject,
  }) {
    //  ... (نفس كود _buildProjectItemCard، ولكن تأكدي أن `ProjectSupervisionDetailsScreen` موجودة أو علقي الانتقال إليها)
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color:
          isSupervisionProject
              ? AppColors.accent.withOpacity(0.05)
              : AppColors.card, // لون مختلف قليلاً لمشاريع الإشراف
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          logger.i(
            "Tapped on project: ${project.name}, ID: ${project.id}, Supervision: $isSupervisionProject",
          );
          if (isSupervisionProject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ProjectSupervisionDetailsScreen(projectId: project.id),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ProjectDetailsViewScreen(projectId: project.id),
              ),
            ).then((value) {
              if (value == true) _refreshAllProjects();
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.start, //  للتأكد من محاذاة الـ Chip
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ), //  زيادة maxLines
                  if (project.status != null)
                    _getStatusColor(project.status!) !=
                            Colors
                                .transparent //  لا تعرضي الـ Chip إذا لم يكن له لون (افتراضي)
                        ? Chip(
                          label: Text(
                            project.status!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: _getStatusColor(project.status!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 0,
                          ), // تعديل الـ padding
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        )
                        : SizedBox(
                          width: 50,
                        ), //  مساحة فارغة إذا لم يكن هناك status chip
                ],
              ),
              const SizedBox(height: 5),
              if (project.description != null &&
                  project.description!.isNotEmpty)
                Text(
                  project.description!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ), // تصغير الخط
              const Spacer(), //  لدفع التاريخ للأسفل
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween, // لوضع أيقونة الإشراف في النهاية
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(project.createdAt.toLocal()),
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (isSupervisionProject)
                    Tooltip(
                      message: "Supervision Project",
                      child: Icon(
                        Icons.remove_red_eye_outlined,
                        size: 15,
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    // ... (نفس الكود)
    switch (status.toLowerCase().replaceAll(' ', '').replaceAll('-', '')) {
      case 'pendingofficeapproval':
        return Colors.orange.shade700;
      case 'officeapprovedawaitingdetails':
        return Colors.blue.shade700;
      case 'detailssubmittedpendingofficereview':
        return Colors.teal.shade700;
      case 'awaitingpaymentproposalbyoffice':
        return Colors.purple.shade700;
      case 'paymentproposalsent':
      case 'awaitinguserpayment':
        return Colors.deepPurple.shade700;
      case 'inprogress':
        return Colors.lightBlue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'officerejected':
      case 'cancelled':
        return Colors.red.shade700;
      case 'pendingsupervisionapproval':
        return Colors.amber.shade800;
      case 'supervisionrequestrejected':
        return Colors.red.shade400;
      case 'underofficesupervision':
        return AppColors.accent;
      case 'supervisionpaymentproposed':
        return Colors.indigo.shade700;
      case 'awaitingsupervisionpayment':
        return Colors.indigo.shade400;
      case 'supervisioncompleted':
        return Colors.green.shade800;
      case 'supervisioncancelled':
        return Colors.red.shade800;
      default:
        return Colors
            .transparent; //  عدم إظهار الـ Chip إذا لم تكن هناك حالة معروفة
    }
  }
}
