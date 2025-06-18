// screens/supervision/select_project_for_supervision_screen.dart
import 'package:buildflow_frontend/models/Basic/project_model.dart';
import 'package:buildflow_frontend/services/create/project_service.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
//  افترض أن هذه هي شاشة اختيار الشركة (الخطوة التالية في التراك الحالي)
import 'select_company_supervision.dart';
// ✅✅✅ استيراد شاشة "ما قبل الاتفاقية" أو شاشة إنشاء المشروع الجديدة ✅✅✅
import '../Design/design_agreement_screen.dart'; //  افترض أن هذا هو اسم ومسار شاشتك

final Logger logger = Logger();

class SelectProjectForSupervisionScreen extends StatefulWidget {
  const SelectProjectForSupervisionScreen({super.key});

  @override
  State<SelectProjectForSupervisionScreen> createState() =>
      _SelectProjectForSupervisionScreenState();
}

class _SelectProjectForSupervisionScreenState
    extends State<SelectProjectForSupervisionScreen> {
  final ProjectService _projectService = ProjectService();
  //  سنستخدم ProjectModel لأن getMyProjectsu يفترض أنها ترجع هذا النوع
  late Future<List<ProjectModel>> _userProjectsFuture;

  @override
  void initState() {
    super.initState();
    _userProjectsFuture = _loadUserProjectsForSupervision();
  }

  Future<List<ProjectModel>> _loadUserProjectsForSupervision() async {
    logger.i("Loading user's projects for supervision selection...");
    try {
      //  تأكدي أن getMyProjectsu ترجع List<ProjectModel>
      //  إذا كانت ترجع List<ProjectsimplifiedModel>، ستحتاجين لتغيير النوع هنا وفي FutureBuilder
      final projects = await _projectService.getMyProjectsu();
      logger.i("Fetched ${projects.length} projects for user.");
      return projects;
    } catch (e, s) {
      logger.e(
        "Error loading user projects for supervision",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<void> _refreshProjects() async {
    if (mounted) {
      setState(() {
        _userProjectsFuture = _loadUserProjectsForSupervision();
      });
    }
  }

  bool _canRequestSupervision(ProjectModel project) {
    //  من الكود الذي أرسلته، يبدو أن هذه الدالة يجب أن تعتمد على project.status
    //  و project.supervisingOfficeId (الذي يجب إضافته لـ ProjectModel.dart إذا لم يكن موجوداً)
    //  مثال:
    //  return project.status?.toLowerCase() == 'design completed' && project.supervisingOfficeId == null;
    //  حالياً سأتركها كما هي في كودك:
    if (project.status?.toLowerCase() == 'completed' &&
        project.supervisingOfficeId == null) {
      return true;
    }
    return false;
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
                  'Select Project for Supervision',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
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
                  onPressed: _refreshProjects,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            //  ✅  تغيير إلى Column ليحتوي على الزر الجديد وقائمة المشاريع
            children: [
              // ✅✅✅  إضافة زر "إنشاء مشروع جديد" هنا ✅✅✅
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16.0,
                  20.0,
                  16.0,
                  12.0,
                ), //  إضافة padding
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  label: const Text(
                    'Create New Project for Design',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    logger.i(
                      "Navigating to PreAgreementScreen to create a new design project.",
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const DesignAgreementScreen(projectId: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), //  ليأخذ عرض الشاشة
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              //  Divider أو SizedBox للفصل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "OR SELECT EXISTING",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ✅  قائمة المشاريع أصبحت Expanded لتأخذ المساحة المتبقية
              Expanded(
                child: FutureBuilder<List<ProjectModel>>(
                  future: _userProjectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        /* ... رسالة الخطأ كما هي ... */
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                                onPressed: _refreshProjects,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        /* ... رسالة لا يوجد مشاريع كما هي ... */
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_off_outlined,
                                size: 80,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You have no projects eligible for supervision request.',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final projects = snapshot.data!;
                      final eligibleProjects =
                          projects
                              .where((p) => _canRequestSupervision(p))
                              .toList();

                      if (eligibleProjects.isEmpty) {
                        return Center(
                          /* ... رسالة لا يوجد مشاريع مؤهلة كما هي ... */
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.playlist_add_check_circle_outlined,
                                  size: 80,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All your current projects either have supervisors or are not ready for supervision requests.',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppColors.textPrimary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      //  ListView أو GridView كما هي
                      return crossAxisCount > 1
                          ? GridView.builder(
                            /* ... */
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0,
                              16.0,
                              16.0,
                            ), // تعديل الـ padding
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16.0,
                                  crossAxisSpacing: 16.0,
                                  childAspectRatio: 1.3,
                                ),
                            itemCount: eligibleProjects.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildSupervisionProjectCard(
                                      eligibleProjects[index],
                                    ),
                          )
                          : ListView.builder(
                            /* ... */
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0,
                              16.0,
                              16.0,
                            ), // تعديل الـ padding
                            itemCount: eligibleProjects.length,
                            itemBuilder:
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildSupervisionProjectCard(
                                    eligibleProjects[index],
                                  ),
                                ),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisionProjectCard(ProjectModel project) {
    // ... (الكود كما هو، مع تعديل بسيط على onPressed للانتقال)
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${project.status}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                //  مثال لعرض supervisingOfficeId إذا كان موجوداً في ProjectModel
                if (project.supervisingOfficeId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Supervising Office ID: ${project.supervisingOfficeId}',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.supervisor_account_outlined, size: 18),
                label: const Text('Request Supervision'),
                onPressed: () {
                  logger.i(
                    "Requesting supervision for project ID: ${project.id}, Name: ${project.name}",
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SelectCompanyForSupervisionScreen(
                            projectId: project.id,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
