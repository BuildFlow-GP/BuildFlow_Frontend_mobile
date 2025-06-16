// screens/supervision/select_project_for_supervision_screen.dart
import 'package:buildflow_frontend/models/Basic/project_model.dart'; //  استخدمي ProjectModel الكامل إذا كان API يرجعه
// أو استخدمي ProjectsimplifiedModel إذا كان كافياً
import 'package:buildflow_frontend/services/create/project_service.dart'; //  تأكدي أن اسم الملف create/project_service.dart
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'select_company_supervision.dart';

//  افترض أن هذه هي الشاشة التالية

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
  late Future<List<ProjectModel>> _userProjectsFuture; //  أو List<ProjectModel>

  @override
  void initState() {
    super.initState();
    _userProjectsFuture = _loadUserProjectsForSupervision();
  }

  Future<List<ProjectModel>> _loadUserProjectsForSupervision() async {
    //  هنا، دالة getMyProjects يفترض أنها ترجع كل مشاريع المستخدم
    //  قد تحتاجين لفلترة إضافية هنا في Flutter إذا لم يكن الـ API يفلتر
    //  لإظهار فقط المشاريع التي "يمكن" طلب إشراف لها.
    //  أو تعديل API getMyProjects ليقبل معامل فلترة.
    //  حالياً، سأفترض أننا نعرض كل مشاريع المستخدم، والتحقق من إمكانية طلب الإشراف سيكون عند بناء الكرت.
    logger.i("Loading user's projects for supervision selection...");
    try {
      //  إذا كانت getMyProjects ترجع List<ProjectModel>، عدلي النوع هنا
      final projects = await _projectService.getMyProjectsu();
      logger.i("Fetched ${projects.length} projects for user.");
      return projects;
    } catch (e, s) {
      logger.e(
        "Error loading user projects for supervision",
        error: e,
        stackTrace: s,
      );
      rethrow; //  ليتمكن FutureBuilder من الإمساك بالخطأ
    }
  }

  Future<void> _refreshProjects() async {
    if (mounted) {
      setState(() {
        _userProjectsFuture = _loadUserProjectsForSupervision();
      });
    }
  }

  //  دالة لتحديد ما إذا كان يمكن طلب إشراف لمشروع معين
  bool _canRequestSupervision(ProjectModel project) {
    //  أو ProjectModel
    //  ✅✅✅  هنا تضعين شروطك ✅✅✅
    //  مثال: المشروع مكتمل من ناحية التصميم، وليس لديه مكتب مشرف حالياً
    if (project.status?.toLowerCase() == 'completed' /* من مرحلة التصميم */ &&
        project.supervisingOfficeId ==
            null /* افترض أن لديك هذا الحقل في الموديل */ ) {
      return true;
    }
    //  أو أي حالات أخرى مناسبة
    //  مثال آخر: إذا كان المشروع لا يزال قيد الإنشاء ولكن المستخدم يريد إشرافاً مبكراً
    // if (project.status?.toLowerCase() == 'in progress' && project.supervisingOfficeId == null) {
    //   return true;
    // }
    return false; //  افتراضياً لا يمكن
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
        //  AppBar مشابه لـ MyProjectsScreen
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
          child: FutureBuilder<List<ProjectModel>>(
            //  أو List<ProjectModel>
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 80,
                          color: AppColors.textSecondary,
                        ), // أيقونة مختلفة
                        const SizedBox(height: 16),
                        Text(
                          'You have no projects eligible for supervision request.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        //  يمكنكِ إضافة زر لإنشاء مشروع جديد إذا كان هذا مناسباً هنا
                      ],
                    ),
                  ),
                );
              } else {
                final projects = snapshot.data!;
                //  فلترة إضافية في الـ UI لإظهار فقط المشاريع التي يمكن طلب إشراف لها
                //  أو الأفضل أن يقوم الـ API بهذا الفلترة
                final eligibleProjects =
                    projects.where((p) => _canRequestSupervision(p)).toList();

                if (eligibleProjects.isEmpty) {
                  return Center(
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

                return crossAxisCount > 1
                    ? GridView.builder(
                      /* ... نفس GridView.builder من MyProjectsScreen ... */
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                        childAspectRatio: 1.3,
                      ), // تعديل النسبة
                      itemCount: eligibleProjects.length,
                      itemBuilder:
                          (context, index) => _buildSupervisionProjectCard(
                            eligibleProjects[index],
                          ),
                    )
                    : ListView.builder(
                      /* ... نفس ListView.builder من MyProjectsScreen ... */
                      padding: const EdgeInsets.all(16.0),
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
      ),
    );
  }

  //  ✅✅✅ ويدجت جديدة لكرت المشروع في هذه الشاشة ✅✅✅
  Widget _buildSupervisionProjectCard(ProjectModel project) {
    // أو ProjectModel
    //  يمكنكِ استخدام تصميم مشابه لـ MyProjectCard ولكن مع زر "Request Supervision"
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, //  لتوزيع العناصر
          children: [
            Column(
              //  لتفاصيل المشروع
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
                //  يمكنكِ إضافة المزيد من التفاصيل هنا إذا أردتِ (مثل تاريخ الإنشاء، المكتب المصمم إذا وجد)
                //  مثال: if (project is ProjectModel && project.designOffice != null) Text('Designer: ${project.designOffice.name}')
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
                  //  الانتقال لشاشة اختيار الشركة (الخطوة التالية في التراك)
                  //  مرري projectId
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
