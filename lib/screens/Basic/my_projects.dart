import 'package:buildflow_frontend/services/session.dart' show Session;
import 'package:flutter/material.dart';
// import '../../models/Basic/project_model.dart';
import '../../services/create/project_service.dart';

// import '../../models/userprojects/project_simplified_model.dart';

import '../../widgets/Suggestions/my_project_card.dart';
import '../Design/my_project_details.dart';
import 'package:buildflow_frontend/themes/app_colors.dart'; // استيراد AppColors
// تأكد من وجود تعريف للـ logger إذا لم يكن موجودًا
// import 'package:logger/logger.dart';
// final Logger logger = Logger();

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  final ProjectService _projectService = ProjectService();

  late Future<List<dynamic>> _myProjectsFuture;
  String? _sessionUserType;

  // ignore: unused_field
  final bool _isLoadingUserType = true; //  لتتبع تحميل نوع المستخدم

  // ignore: unused_field
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _myProjectsFuture = _loadDataBasedOnUserType();
  }

  Future<List<dynamic>> _loadDataBasedOnUserType() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    try {
      _sessionUserType = await Session.getUserType();
      if (!mounted) return [];

      if (_sessionUserType == null) {
        throw Exception("User type not found in session.");
      }

      if (_sessionUserType!.toLowerCase() == 'office') {
        // logger.i("Loading projects for OFFICE");
        return await _projectService.getAssignedOfficeProjects();
      } else if (_sessionUserType!.toLowerCase() == 'individual') {
        // logger.i("Loading projects for INDIVIDUAL");
        return await _projectService.getMyProjects();
      } else {
        throw Exception("Unknown user type: $_sessionUserType");
      }
    } catch (e) {
      // logger.e("Error in _loadDataBasedOnUserType", error: e, stackTrace: s);
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _refreshProjects() async {
    if (mounted) {
      // logger.i("Refreshing projects for user type: $_sessionUserType");
      setState(() {
        _myProjectsFuture = _loadDataBasedOnUserType();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ضبط عرض المحتوى بناءً على حجم الشاشة (متجاوب)
    double screenWidth = MediaQuery.of(context).size.width;
    // أقصى عرض 800px في الشاشات الكبيرة، أو 100% من عرض الشاشة في الموبايل
    // يمكنك زيادة هذا الرقم إذا أردت مساحة أكبر للمحتوى على الشاشات العريضة جداً
    double contentMaxWidth = screenWidth > 1200 ? 1200 : screenWidth;

    // ✨ تحديد عدد الأعمدة بناءً على عرض الشاشة
    int crossAxisCount;
    if (screenWidth >= 1024) {
      // شاشات سطح المكتب/الأجهزة اللوحية الكبيرة: 3 أعمدة
      crossAxisCount = 3;
    } else if (screenWidth >= 768) {
      // شاشات الأجهزة اللوحية المتوسطة: 2 عمود
      crossAxisCount = 2;
    } else {
      // الهواتف/الأجهزة اللوحية الصغيرة: عمود واحد (ListView)
      crossAxisCount = 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background, // خلفية الشاشة من AppColors
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
              // زر الرجوع
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                color: AppColors.accent, // لون زر الرجوع من AppColors
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'My Projects', // عنوان الصفحة
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent, // لون العنوان من AppColors
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // زر التحديث
              SizedBox(
                width: 48, // حجم ثابت ليتناسق مع زر الرجوع
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  color: AppColors.accent, // لون زر التحديث من AppColors
                  tooltip: 'Refresh Projects',
                  onPressed:
                      _isLoadingUserType ||
                              _isInitializing // استخدم الحالات الصحيحة للتعطيل
                          ? null
                          : _refreshProjects,
                ),
              ),
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
          child: FutureBuilder<List<dynamic>>(
            future: _myProjectsFuture,
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
                          onPressed: () => _refreshProjects(),
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
                          Icons.folder_open_rounded, // أيقونة جديدة
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects found.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by creating a new project!', // رسالة توضيحية
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Project'),
                          onPressed: () {
                            // أضف هنا منطق الانتقال إلى صفحة إنشاء مشروع
                            // مثلاً: Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProjectScreen()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Create Project functionality not yet implemented.',
                                ),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final projects = snapshot.data!;

                // ✨ استخدم crossAxisCount لتحديد ما إذا كان ListView أو GridView
                return crossAxisCount > 1
                    ? GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, // استخدام العدد المحدد
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                        // يمكنك تعديل childAspectRatio لتناسب ارتفاع الكارت
                        // 1.2 يعني أن العرض سيكون 1.2 ضعف الارتفاع.
                        // إذا كانت كروت MyProjectCard قصيرة، قد تحتاج لزيادة هذا الرقم (مثلاً 1.5 أو 1.8).
                        // إذا كانت طويلة، قد تحتاج لتقليله (مثلاً 1.0 أو 0.8).
                        childAspectRatio: 1.2,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _buildProjectItemCard(
                          project,
                        ); // استخدم دالة بناء الكارت
                      },
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildProjectItemCard(
                            project,
                          ), // استخدم دالة بناء الكارت
                        );
                      },
                    );
              }
            },
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء بطاقة المشروع الفردية
  Widget _buildProjectItemCard(dynamic project) {
    return Container(
      margin: EdgeInsets.zero,

      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProjectDetailsViewScreen(projectId: project.id),
            ),
          ).then((value) {
            if (value == true) {
              _refreshProjects();
            }
          });
          // logger.i("Tapped on project: ${project.name}");
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: MyProjectCard(
            // استخدام MyProjectCard هنا
            project: project,
            // MyProjectCard يجب أن لا تحتوي على Gesture Detector خاص بها
            // ولا يجب أن تحتوي على padding أو margin خاص بها إذا كنت تريد هذا الـ wrapper للتحكم في التباعد
            // قد تحتاج لتعديل MyProjectCard لتكون "pure" widget (أي لا تحتوي على تزيينات خارجية أو منطق onTap)
            onTap: () {
              /* لا تفعل شيئًا هنا لأن الـ InkWell الخارجي سيتعامل مع الـ tap */
            },
          ),
        ),
      ),
    );
  }
}
