// screens/Design/my_project_details.dart (أو اسم ملفك الصحيح)
import 'package:buildflow_frontend/models/Basic/user_model.dart';
import 'package:buildflow_frontend/services/create/project_design_service.dart'; // للتعديل على تفاصيل التصميم
import 'package:buildflow_frontend/services/create/user_update_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import 'planner_5d_viewer_screen.dart';
import '../../services/create/project_service.dart'; // تم تغيير المسار
import '../../services/session.dart';
import '../../models/Basic/project_model.dart'; // الموديل المحدث الذي أرسلتيه

import '../../themes/app_colors.dart';
import '../../utils/constants.dart';

import 'project_description.dart'; // لتعديل وصف التصميم
import 'payment_screen.dart'; //  للدفع (TODO)
import '../Profiles/office_profile.dart'; // لعرض بروفايل المكتب

final Logger logger = Logger(
  printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5),
);

class ProjectDetailsViewScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailsViewScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsViewScreen> createState() =>
      _ProjectDetailsViewScreenState();
}

class _ProjectDetailsViewScreenState extends State<ProjectDetailsViewScreen> {
  final ProjectService _projectService = ProjectService();
  // ignore: unused_field
  final ProjectDesignService _projectDesignService = ProjectDesignService();
  final UserService _userService = UserService();

  ProjectModel? _project;
  UserModel? _currentUser;
  String? _sessionUserType;

  bool _isLoading = true;
  String? _error;

  // حالات UI للمكتب
  bool _isOfficeProposingPayment = false;
  bool _isOfficeUpdatingProgress = false;
  bool _isOfficeUploadingFile = false; //  حالة عامة لرفع أي ملف من المكتب
  bool _isOfficeEditingName = false;

  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  late TextEditingController
  _projectNameController; //  سيتم تهيئته في initState

  final List<String> _progressStageLabels = [
    "Kick-off", // Stage 0
    "Architectural Design", // Stage 1 (يرفع architectural_file)
    "Structural Design", // Stage 2 (يرفع structural_file)
    "Electrical Design", // Stage 3 (يرفع electrical_file)
    "Mechanical Design", // Stage 4 (يرفع mechanical_file)
    "Final 2D Drawings", // Stage 5 (يرفع document_2d)
  ];
  //  أسماء حقول الملفات في ProjectModel لمراحل التقدم (للمكتب)
  //  و formFieldName الذي يتوقعه multer
  final Map<int, Map<String, String>> _officeProgressFileMapping = {
    1: {
      'dbField': 'architectural_file',
      'formField': 'architecturalFile',
      'label': 'Architectural Docs',
    },
    2: {
      'dbField': 'structural_file',
      'formField': 'structuralFile',
      'label': 'Structural Docs',
    },
    3: {
      'dbField': 'electrical_file',
      'formField': 'electricalFile',
      'label': 'Electrical Docs',
    },
    4: {
      'dbField': 'mechanical_file',
      'formField': 'mechanicalFile',
      'label': 'Mechanical Docs',
    },
    5: {
      'dbField': 'document_2d',
      'formField': 'final2dFile',
      'label': 'Final 2D Drawings',
    },
  };

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController(); // تهيئة هنا
    _loadInitialData();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData({bool showLoadingIndicator = true}) async {
    if (!mounted) return;
    if (showLoadingIndicator) {
      setState(() => _isLoading = true);
    }
    _error = null;

    try {
      final results = await Future.wait([
        _projectService.getbyofficeProjectDetails(widget.projectId),
        _userService.getCurrentUserDetails(),
        Session.getUserType(),
      ]);

      if (mounted) {
        setState(() {
          _project = results[0] as ProjectModel?; //  جعل الـ cast اختياري
          _currentUser = results[1] as UserModel?;
          _sessionUserType = results[2] as String?;

          if (_project != null) {
            _projectNameController.text = _project!.name;
            if (_project!.proposedPaymentAmount != null) {
              _paymentAmountController.text = _project!.proposedPaymentAmount!
                  .toStringAsFixed(2);
            }
            _paymentNotesController.text = _project!.paymentNotes ?? '';
          } else {
            _error = "Project data could not be loaded.";
          }
          _isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e(
        "Error loading project details for view screen",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        setState(() {
          _error =
              "Failed to load project data. Please try again. (${e.toString()})";
          _isLoading = false;
        });
      }
    }
  }

  // === دوال الأفعال للمكتب ===
  Future<void> _handleProposePayment() async {
    if (_isOfficeProposingPayment || _project == null) return;
    final amount = double.tryParse(_paymentAmountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid payment amount.")),
        );
      }
      return;
    }
    setState(() => _isOfficeProposingPayment = true);
    try {
      final updatedProject = await _projectService.proposePayment(
        widget.projectId,
        amount,
        _paymentNotesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment proposal sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _project = updatedProject);
      }
    } catch (e) {
      logger.e("Error proposing payment", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send proposal: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isOfficeProposingPayment = false);
    }
  }

  Future<void> _handleOfficeUploadFile(
    String dbFieldKey,
    String formFieldName,
    String friendlyName,
  ) async {
    if (_isOfficeUploadingFile || _project == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          (dbFieldKey == 'document_3d') //  الـ 3D الاختياري من المكتب
              ? ['skp', 'max', 'obj', 'fbx', 'glb', 'gltf', 'zip']
              : ['pdf', 'dwg', 'zip', 'jpg', 'png'],
      withData: kIsWeb,
    );

    if (result != null) {
      PlatformFile file = result.files.single;
      final fileSizeLimit =
          (dbFieldKey == 'document_3d')
              ? (50 * 1024 * 1024)
              : (10 * 1024 * 1024); // 50MB for 3D, 10MB for others
      if (file.size > fileSizeLimit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "File is too large (max ${fileSizeLimit / (1024 * 1024)}MB).",
              ),
            ),
          );
        }
        return;
      }
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes != null) {
        setState(() => _isOfficeUploadingFile = true);
        try {
          String? uploadedPath;
          //  استدعاء دالة الرفع المناسبة من ProjectService
          if (dbFieldKey == 'architectural_file') {
            uploadedPath = await _projectService.uploadArchitecturalFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else if (dbFieldKey == 'structural_file') {
            uploadedPath = await _projectService.uploadArchitecturalFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else if (dbFieldKey == 'document_2d') {
            uploadedPath = await _projectService.uploadFinal2DFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else if (dbFieldKey == 'electrical_file') {
            uploadedPath = await _projectService.uploadArchitecturalFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else if (dbFieldKey == 'mechanical_file') {
            uploadedPath = await _projectService.uploadArchitecturalFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else if (dbFieldKey == 'document_3d') {
            uploadedPath = await _projectService.uploadArchitecturalFile(
              widget.projectId,
              fileBytes,
              file.name,
            );
          } else {
            throw Exception(
              "Unsupported document key for office upload: $dbFieldKey",
            );
          }

          if (uploadedPath != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$friendlyName uploaded successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            _loadInitialData(showLoadingIndicator: false);
          }
        } catch (e) {
          logger.e("Error uploading $friendlyName", error: e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Failed to upload $friendlyName: ${e.toString()}",
                ),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isOfficeUploadingFile = false);
        }
      }
    }
  }

  Future<void> _handleUpdateProgress(int newStage) async {
    if (_isOfficeUpdatingProgress || _project == null) return;
    //  التأكد أن المرحلة الجديدة مرتبطة بملف تم رفعه (باستثناء المرحلة 0)
    //   if (newStage > 0 && newStage <= 5) {
    //  للمراحل 1-5 التي لها ملفات
    String? docKey = _officeProgressFileMapping[newStage]?['dbField'];
    if (docKey != null) {
      String? filePath = _getProjectDocumentPath(docKey);
      if (filePath == null || filePath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Please upload the '${_officeProgressFileMapping[newStage]?['label']}' document before marking this stage as current.",
              ),
            ),
          );
        }
        return;
      }
    }
    // } else if (newStage == 0 && (_project!.progressStage ?? 0) != 0) {
    //   //  لا تسمحي بالرجوع للمرحلة 0 إذا لم تكن هي الحالية
    // }

    setState(() => _isOfficeUpdatingProgress = true);
    try {
      final updatedProject = await _projectService.updateProjectProgress(
        widget.projectId,
        newStage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project progress updated!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _project = updatedProject);
      }
    } catch (e) {
      logger.e("Error updating progress", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update progress: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isOfficeUpdatingProgress = false);
    }
  }

  Future<void> _handleUpdateProjectName() async {
    if (_projectNameController.text.isEmpty ||
        _isOfficeEditingName ||
        _project == null) {
      return;
    }
    if (_projectNameController.text.trim() == _project!.name) {
      if (mounted) setState(() => _isOfficeEditingName = false);
      return;
    }
    setState(() => _isOfficeEditingName = true);
    try {
      final updatedProject = await _projectService.updatebyofficeProjectDetails(
        widget.projectId,
        {'name': _projectNameController.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project name updated!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _project = updatedProject);
      }
    } catch (e) {
      logger.e("Error updating project name", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update project name: ${e.toString()}"),
          ),
        );
        _projectNameController.text = _project?.name ?? '';
      }
    } finally {
      if (mounted) setState(() => _isOfficeEditingName = false);
    }
  }

  // === دوال خاصة بالمستخدم ===
  void _handleEditDesignDetails() {
    if (_project == null) return;
    const editableStates = [
      'Office Approved - Awaiting Details',
      'Details Submitted - Pending Office Review',
      'Payment Proposal Sent',
      'Awaiting User Payment',
    ];
    if (editableStates.contains(_project!.status)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ProjectDescriptionScreen(projectId: widget.projectId),
        ),
      ).then((value) {
        if (value == true || value == null) {
          //  افترض أن true تعني أن هناك تحديثاً
          _loadInitialData(showLoadingIndicator: false);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Design details cannot be edited in project status: '${_project!.status}'",
          ),
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _handleUserUploadLicense() async {
    if (_isOfficeUploadingFile || _project == null) {
      return; //  استخدم نفس متغير التحميل مبدئياً
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: kIsWeb,
    );
    if (result != null) {
      PlatformFile file = result.files.single;
      if (file.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File is too large (max 20MB).")),
          );
        }
        return;
      }
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes != null) {
        setState(
          () => _isOfficeUploadingFile = true,
        ); //  إعادة استخدام نفس الـ flag
        try {
          final uploadedPath = await _projectService.uploadLicenseFile(
            widget.projectId,
            fileBytes,
            file.name,
          );
          if (uploadedPath != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("License file uploaded successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            _loadInitialData(showLoadingIndicator: false);
          }
        } catch (e) {
          logger.e("Error uploading license file", error: e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to upload license: ${e.toString()}"),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isOfficeUploadingFile = false);
        }
      }
    }
  }

  void _handleMakePayment() {
    if (_project == null) return;
    const paymentRequiredStates = [
      'Payment Proposal Sent',
      'Awaiting User Payment',
    ];
    if (paymentRequiredStates.contains(_project!.status) &&
        _project!.proposedPaymentAmount != null &&
        _project!.proposedPaymentAmount! > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentScreen(
                projectId: widget.projectId,
                totalAmount: _project!.proposedPaymentAmount!,
              ),
        ),
      );
      logger.i(
        "TODO: Navigate to PaymentScreen for project ${widget.projectId}, amount: ${_project!.proposedPaymentAmount}",
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Payment Screen")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No pending payment or payment not yet proposed by office.",
          ),
        ),
      );
    }
  }

  void _handleView3DViaPlanner5D() {
    if (_project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project data not loaded yet.")),
      );
      return;
    }

    //  افترض أن لديك حقل planner_5d_url في ProjectModel
    //  أو أنكِ ستبنين الـ URL هنا إذا كنتِ تحفظين الـ key فقط
    // ignore: unused_local_variable
    final String? projectPlannerUrl =
        _project!.planner5dUrl; //  ✅  افترضي أن هذا الحقل موجود

    if (_project == null || _project!.planner5dUrl == null) {
      logger.w("Planner 5D URL is null or project data not loaded.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("3D view link is not available.")),
      );
      return;
    }

    String cleanedUrl = _project!.planner5dUrl!
        .trim()
        .replaceAll('\n', '')
        .replaceAll('\r', '');

    logger.i(
      "Type of cleanedUrl: ${cleanedUrl.runtimeType}",
    ); // ✅✅✅ أضيفي هذا ✅✅✅
    logger.i(
      "Cleaned Planner 5D URL for WebView: '$cleanedUrl'",
    ); //  أضيفي علامات اقتباس للتأكد من عدم وجود مسافات خفية

    if (cleanedUrl.isNotEmpty &&
        (cleanedUrl.startsWith('http://') ||
            cleanedUrl.startsWith('https://'))) {
      try {
        Uri testUri = Uri.parse(cleanedUrl); //  ✅✅✅ اختبار Uri.parse ✅✅✅
        logger.i(
          "Uri.parse successful. Scheme: ${testUri.scheme}, Host: ${testUri.host}, Path: ${testUri.path}, IsAbsolute: ${testUri.isAbsolute}",
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Planner5DViewerScreen(plannerUrl: cleanedUrl),
          ),
        );
      } catch (e, s) {
        logger.e(
          "Error during Uri.parse('$cleanedUrl')",
          error: e,
          stackTrace: s,
        ); // ✅✅✅
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error parsing 3D link: ${e.toString()}")),
        );
      }
    } else {
      logger.e("Invalid or empty URL after cleaning: '$cleanedUrl'");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("3D view link is improperly formatted.")),
      );
    }
  }

  final dateFormat = DateFormat('dd MMM, yyyy');
  final currencyFormat = NumberFormat.currency(
    locale: 'ar_JO',
    symbol: 'د.أ',
    name: 'JOD',
  );

  Widget _buildInfoRow(
    String label,
    String? value, {
    IconData? icon,
    bool isLink = false,
    VoidCallback? onLinkTap,
  }) {
    if (value == null || value.isEmpty || value.toLowerCase() == 'n/a') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child:
                icon != null
                    ? Icon(
                      icon,
                      size: 16,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    )
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child:
                isLink
                    ? InkWell(
                      onTap:
                          onLinkTap ??
                          () async {
                            String fullUrl =
                                '${Constants.baseUrl}/documents/archdocument'; //  تكوين الـ URL
                            logger.i(
                              "Attempting to open document link: $fullUrl",
                            );

                            final uri = Uri.parse(fullUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              ); //  يفتح في المتصفح/التطبيق المناسب
                            } else {
                              logger.e('Could not launch $fullUrl');
                              if (mounted) {
                                // تأكدي أن mounted متاح إذا كنتِ داخل State
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not open the document link.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                      child: Text(
                        value.split('/').last,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontSize: 13.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    : Text(
                      value,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20.0,
        bottom: 8.0,
        left: 4.0,
        right: 4.0,
      ), //  إضافة padding أفقي بسيط
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == null || status.isEmpty) return const SizedBox.shrink();
    Color statusColor = Colors.grey.shade600;
    IconData statusIcon = Icons.info_outline_rounded;
    switch (status.toLowerCase().replaceAll(' ', '').replaceAll('-', '')) {
      case 'pendingofficeapproval':
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'officeapprovedawaitingdetails':
        statusColor = Colors.blue.shade700;
        statusIcon = Icons.playlist_add_check_rounded;
        break;
      case 'detailssubmittedpendingofficereview':
        statusColor = Colors.teal.shade700;
        statusIcon = Icons.rate_review_outlined;
        break;
      case 'awaitingpaymentproposalbyoffice':
        statusColor = Colors.purple.shade700;
        statusIcon = Icons.request_quote_outlined;
        break;
      case 'paymentproposalsent':
      case 'awaitinguserpayment':
        statusColor = Colors.deepPurple.shade700;
        statusIcon = Icons.payment_outlined;
        break;
      case 'inprogress':
        statusColor = Colors.lightBlue.shade700;
        statusIcon = Icons.construction_rounded;
        break;
      case 'completed':
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'officerejected':
      case 'cancelled':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel_rounded;
        break;
    }
    return Chip(
      avatar: Icon(statusIcon, color: Colors.white, size: 15),
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: const EdgeInsets.only(left: 3, right: 5),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildEntityCard({
    required String name,
    String? imageUrl,
    String? typeLabel,
    IconData defaultIcon = Icons.person,
    VoidCallback? onTap,
  }) {
    // ... (الكود كما هو)
    ImageProvider? imageProv;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProv = NetworkImage(imageUrl);
    }
    return Card(
      elevation: 1,
      shadowColor: AppColors.shadow.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundImage: imageProv,
          onBackgroundImageError: imageProv != null ? (_, __) {} : null,
          backgroundColor: AppColors.background,
          child:
              imageProv == null
                  ? Icon(defaultIcon, size: 16, color: AppColors.textSecondary)
                  : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle:
            typeLabel != null
                ? Text(
                  typeLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                )
                : null,
        onTap: onTap,
        trailing:
            onTap != null
                ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.accent.withOpacity(0.7),
                )
                : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _project?.name ?? 'Loading Project...',
          style: const TextStyle(fontSize: 18),
        ), // تصغير الخط
        backgroundColor: AppColors.accent,

        elevation: 0.5, // تقليل الظل
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Project Data',
            onPressed: _isLoading ? null : () => _loadInitialData(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
              : _project == null
              ? const Center(
                child: Text(
                  'Project data could not be loaded. Please go back and try again.',
                ),
              ) // رسالة أوضح
              : _buildProjectContentView(),
    );
  }

  Widget _buildProjectContentView() {
    if (_project == null || _currentUser == null || _sessionUserType == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Required data is missing to display project details. Please try refreshing.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final project = _project!;
    final design =
        project
            .projectDesign; //  ProjectModel.projectDesign يجب أن يكون ProjectDesignModel?
    final isUserOwner =
        _currentUser!.id == project.userId &&
        _sessionUserType!.toLowerCase() == 'individual';
    final isAssignedOffice =
        _currentUser!.id == project.officeId &&
        _sessionUserType!.toLowerCase() == 'office';

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(showLoadingIndicator: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 70), // تعديل الحشو
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === معلومات المشروع الأساسية ===
            Card(
              // تغليف كل قسم بـ Card
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child:
                              (isAssignedOffice &&
                                      [
                                        'Pending Office Approval',
                                        'Office Approved - Awaiting Details',
                                        'Details Submitted - Pending Office Review',
                                        'In Progress',
                                      ].contains(
                                        project.status,
                                      )) // السماح بتعديل الاسم في حالات أكثر
                                  ? Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _projectNameController,
                                          decoration: const InputDecoration(
                                            hintText: "Project Name",
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 18,
                                          ),
                                          onFieldSubmitted:
                                              (value) =>
                                                  _handleUpdateProjectName(),
                                        ),
                                      ),
                                      _isOfficeEditingName
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : IconButton(
                                            icon: Icon(
                                              Icons.save_alt_rounded,
                                              color: AppColors.accent,
                                              size: 20,
                                            ),
                                            onPressed: _handleUpdateProjectName,
                                            tooltip: "Save Name",
                                          ),
                                    ],
                                  )
                                  : Text(
                                    project.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(project.status),
                      ],
                    ),
                    if (project.description!.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        project.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const Divider(height: 20, thickness: 0.5),
                    _buildInfoRow(
                      'Est. Budget (User):',
                      project.budget != null
                          ? currencyFormat.format(project.budget)
                          : 'N/A',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _buildInfoRow(
                      'Start Date:',
                      project.startDate != null
                          ? dateFormat.format(project.startDate!.toLocal())
                          : 'N/A',
                      icon: Icons.calendar_today_outlined,
                    ),
                    _buildInfoRow(
                      'Expected End Date:',
                      project.endDate != null
                          ? dateFormat.format(project.endDate!.toLocal())
                          : 'N/A',
                      icon: Icons.event_busy_outlined,
                    ),
                    _buildInfoRow(
                      'General Location:',
                      project.location!.isNotEmpty ? project.location : 'N/A',
                      icon: Icons.location_city_outlined,
                    ),
                    _buildInfoRow(
                      'Created:',
                      dateFormat.format(project.createdAt.toLocal()),
                      icon: Icons.history_edu_outlined,
                    ),
                  ],
                ),
              ),
            ),

            if (project.landArea != null || project.plotNumber!.isNotEmpty)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Land Specifics'),
                      _buildInfoRow(
                        'Land Area:',
                        project.landArea != null
                            ? '${project.landArea!.toStringAsFixed(2)} m²'
                            : 'N/A',
                        icon: Icons.landscape_outlined,
                      ),
                      _buildInfoRow(
                        'Plot Number:',
                        project.plotNumber!.isNotEmpty
                            ? project.plotNumber
                            : 'N/A',
                        icon: Icons.signpost_outlined,
                      ),
                      _buildInfoRow(
                        'Basin Number:',
                        project.basinNumber!.isNotEmpty
                            ? project.basinNumber
                            : 'N/A',
                        icon: Icons.confirmation_number_outlined,
                      ),
                      _buildInfoRow(
                        'Land Location (Detail):',
                        project.landLocation!.isNotEmpty
                            ? project.landLocation
                            : 'N/A',
                        icon: Icons.explore_outlined,
                      ),
                    ],
                  ),
                ),
              ),

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Design Specifications (User Input)',
                      trailing:
                          (isUserOwner &&
                                  [
                                    'Office Approved - Awaiting Details',
                                    'Details Submitted - Pending Office Review',
                                    'Payment Proposal Sent',
                                    'Awaiting User Payment',
                                  ].contains(project.status))
                              ? Tooltip(
                                message: "Edit Design Details",
                                child: InkWell(
                                  onTap: _handleEditDesignDetails,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.edit_note_rounded,
                                      color: AppColors.accent,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              )
                              : null,
                    ),
                    if (design != null) ...[
                      _buildInfoRow(
                        'Floors:',
                        design.floorCount?.toString() ?? 'N/A',
                        icon: Icons.stairs_outlined,
                      ),
                      _buildInfoRow(
                        'Bedrooms:',
                        design.bedrooms?.toString() ?? 'N/A',
                        icon: Icons.bed_outlined,
                      ),
                      _buildInfoRow(
                        'Bathrooms:',
                        design.bathrooms?.toString() ?? 'N/A',
                        icon: Icons.bathtub_outlined,
                      ),
                      _buildInfoRow(
                        'Kitchens:',
                        design.kitchens?.toString() ?? 'N/A',
                        icon: Icons.kitchen_outlined,
                      ),
                      _buildInfoRow(
                        'Balconies:',
                        design.balconies?.toString() ?? 'N/A',
                        icon: Icons.balcony_outlined,
                      ),
                      _buildInfoRow(
                        'Kitchen Type:',
                        design.kitchenType ?? 'N/A',
                        icon: Icons.restaurant_menu_outlined,
                      ),
                      _buildInfoRow(
                        'Master Has Bathroom:',
                        design.masterHasBathroom == true
                            ? 'Yes'
                            : (design.masterHasBathroom == false
                                ? 'No'
                                : 'N/A'),
                        icon: Icons.wc_rounded,
                      ),
                      if (design.specialRooms != null &&
                          design.specialRooms!.isNotEmpty)
                        _buildInfoRow(
                          'Special Rooms:',
                          design.specialRooms!.join(', '),
                          icon: Icons.meeting_room_outlined,
                        ),
                      if (design.directionalRooms != null &&
                          design.directionalRooms!.isNotEmpty)
                        Padding(
                          /* ... directional rooms ... */
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.compass_calibration_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Directional Rooms:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 30,
                                  top: 3,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      (design.directionalRooms!
                                              as List<dynamic>)
                                          .map((e) {
                                            final roomMap =
                                                e as Map<String, dynamic>;
                                            return Text(
                                              '• ${roomMap['room']}: ${roomMap['direction']}',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: AppColors.textPrimary,
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (design.budgetMin != null ||
                          design.budgetMax != null) ...[
                        _buildSectionTitle('User\'s Design Budget Range'),
                        _buildInfoRow(
                          'Min:',
                          design.budgetMin != null
                              ? currencyFormat.format(design.budgetMin)
                              : 'N/A',
                          icon: Icons.remove_circle_outline_outlined,
                        ),
                        _buildInfoRow(
                          'Max:',
                          design.budgetMax != null
                              ? currencyFormat.format(design.budgetMax)
                              : 'N/A',
                          icon: Icons.add_circle_outline_outlined,
                        ),
                      ],
                      _buildSectionTitle('User\'s Design Descriptions'),
                      if (design.generalDescription != null &&
                          design.generalDescription!.isNotEmpty)
                        _buildInfoRow(
                          'General:',
                          design.generalDescription,
                          icon: Icons.notes_outlined,
                        ),
                      if (design.interiorDesign != null &&
                          design.interiorDesign!.isNotEmpty)
                        _buildInfoRow(
                          'Interior:',
                          design.interiorDesign,
                          icon: Icons.palette_outlined,
                        ),
                      if (design.roomDistribution != null &&
                          design.roomDistribution!.isNotEmpty)
                        _buildInfoRow(
                          'Room Layout:',
                          design.roomDistribution,
                          icon: Icons.space_dashboard_outlined,
                        ),
                    ] else if ((project.status == 'Office Approved' ||
                            project.status == 'Details Submitted') &&
                        isUserOwner)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "You haven't submitted design details yet.",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.description_outlined),
                                label: const Text("Submit Design Details Now"),
                                onPressed: _handleEditDesignDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Text(
                            "No design details submitted for this project yet.",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (project.office != null || project.user != null)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.office != null) ...[
                        _buildSectionTitle('Assigned Office'),
                        _buildEntityCard(
                          name: project.office!.name,
                          imageUrl: project.office!.profileImage,
                          typeLabel: project.office!.location,
                          defaultIcon: Icons.maps_home_work_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => OfficeProfileScreen(
                                      officeId: project.office!.id,
                                      isOwner: true,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (project.user != null && !isUserOwner) ...[
                        _buildSectionTitle('Project Owner'),
                        _buildEntityCard(
                          name: project.user!.name,
                          imageUrl: project.user!.profileImage,
                          typeLabel: project.user!.email,
                          defaultIcon: Icons.person_outline,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Documents'),
                    _buildDocumentItem(
                      'Agreement:',
                      project.agreementFile,
                      'agreement_file',
                      canUserUpload:
                          isUserOwner &&
                          project.status ==
                              'Office Approved - Awaiting Details',
                    ),
                    _buildDocumentItem(
                      'License:',

                      project.licenseFile,
                      'license_file',
                      canUserUpload: isUserOwner && project.status != '',
                    ),
                    //  ملفات التقدم التي يرفعها المكتب
                    _buildDocumentItem(
                      'Architectural (Office):',
                      project.architecturalfile,
                      'architectural_file',
                    ),
                    _buildDocumentItem(
                      'Structural (Office):',
                      project.structuralfile,
                      'structural_file',
                    ),
                    _buildDocumentItem(
                      'Electrical (Office):',
                      project.electricalfile,
                      'electrical_file',
                    ),
                    _buildDocumentItem(
                      'Mechanical (Office):',
                      project.mechanicalfile,
                      'mechanical_file',
                    ),
                    _buildDocumentItem(
                      'Final 2D (Office):',
                      project.document2D,
                      'document_2d',
                    ),
                    _buildDocumentItem(
                      'Optional 3D (Office):',
                      project.document3D,
                      'document_3d',
                    ),
                  ],
                ),
              ),
            ),

            // === أقسام خاصة بالمكتب ===
            if (isAssignedOffice) ...[
              _buildOfficePaymentSection(project),
              _buildOfficeProgressSection(project), //  يعرض الـ Slider والنسبة
              _buildOfficeDocumentUploadSectionForProgress(
                project,
              ), //  يعرض أزرار رفع ملفات التقدم
            ],

            // === أقسام خاصة بالمستخدم ===
            if (isUserOwner) ...[
              _buildUserPaymentActionSection(project),
              _buildUserProgressViewSection(
                project,
              ), //  ✅✅✅ قسم جديد لعرض التقدم لليوزر ✅✅✅
              _buildUser3DViewSection(project),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // === ويدجتس فرعية للأقسام الخاصة بالمكتب ===
  Widget _buildOfficePaymentSection(ProjectModel project) {
    /* ... نفس الكود ... */
    const SizedBoxtiny = SizedBox(height: 8);
    final bool canProposePayment =
        project.status == 'Details Submitted - Pending Office Review' ||
        project.status == 'Awaiting Payment Proposal by Office';
    final bool paymentAlreadyProposed =
        project.proposedPaymentAmount != null &&
        (project.status == 'Payment Proposal Sent' ||
            project.status == 'Awaiting User Payment' ||
            project.status == 'In Progress' ||
            project.status == 'Completed');
    if (!canProposePayment && !paymentAlreadyProposed) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Payment Proposal (For Office)'),
            if (paymentAlreadyProposed) ...[
              _buildInfoRow(
                'Proposed Amount:',
                currencyFormat.format(project.proposedPaymentAmount!),
                icon: Icons.price_check_rounded,
              ),
              if (project.paymentNotes != null &&
                  project.paymentNotes!.isNotEmpty)
                _buildInfoRow(
                  'Office Notes:',
                  project.paymentNotes,
                  icon: Icons.notes_rounded,
                ),
              _buildInfoRow(
                'Payment Status:',
                project.paymentStatus ?? 'N/A',
                icon: Icons.credit_card_outlined,
              ),
              if (project.paymentStatus?.toLowerCase().contains('pending') ??
                  true)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Payment proposal has been sent to the user.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                )
              else if (project.paymentStatus?.toLowerCase() == 'paid')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Payment received. Project is active.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ] else if (canProposePayment) ...[
              TextFormField(
                controller: _paymentAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Propose Payment Amount (JOD)',
                  prefixText: '${currencyFormat.currencySymbol} ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final pValue = double.tryParse(value);
                  if (pValue == null || pValue <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              SizedBoxtiny,
              TextFormField(
                controller: _paymentNotesController,
                decoration: InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                maxLines: 2,
              ),
              SizedBoxtiny,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      _isOfficeProposingPayment
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.send_and_archive_outlined,
                            size: 18,
                          ),
                  label: Text(
                    _isOfficeProposingPayment
                        ? 'Sending...'
                        : 'Send Payment Proposal to User',
                    style: const TextStyle(fontSize: 14),
                  ),
                  onPressed:
                      _isOfficeProposingPayment ? null : _handleProposePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeProgressSection(ProjectModel project) {
    /* ... نفس الكود ... */
    final bool canUpdateProgress = [
      'In Progress',
      'Details Submitted - Pending Office Review',
      'Awaiting User Payment',
      'Payment Proposal Sent',
    ].contains(project.status);
    if (!canUpdateProgress &&
        project.status != 'Completed' &&
        project.status != 'Pending Office Approval' &&
        project.status != 'Office Approved - Awaiting Details') {
      return const SizedBox.shrink();
    }
    int currentStage = project.progressStage ?? 0;
    if (currentStage < 0) currentStage = 0;
    if (currentStage >= _progressStageLabels.length) {
      currentStage = _progressStageLabels.length - 1;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Update Project Progress (For Office)'),
            if (project.status == 'Completed')
              Center(
                child: Chip(
                  label: Text(
                    "Project Marked as Completed",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  avatar: Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                  ),
                ),
              )
            else if (project.status == 'Pending Office Approval' ||
                project.status == 'Office Approved - Awaiting Details')
              Center(
                child: Chip(
                  label: Text(
                    "Waiting for user to submit details or pay.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  backgroundColor: Colors.grey.shade300,
                  avatar: Icon(
                    Icons.hourglass_empty_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else ...[
              Text(
                "Current Stage: ${_progressStageLabels[currentStage]} (${((currentStage / (_progressStageLabels.length - 1)) * 100).toStringAsFixed(0)}%)",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Slider(
                value: currentStage.toDouble(),
                min: 0,
                max: (_progressStageLabels.length - 1).toDouble(),
                divisions: _progressStageLabels.length - 1,
                label: _progressStageLabels[currentStage],
                activeColor: AppColors.accent,
                inactiveColor: AppColors.primary.withOpacity(0.3),
                onChanged:
                    _isOfficeUpdatingProgress
                        ? null
                        : (double value) {}, //  لا نفعل شيئاً هنا
                onChangeEnd: (double value) {
                  _handleUpdateProgress(value.toInt());
                },
              ),
              if (_isOfficeUpdatingProgress)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: LinearProgressIndicator(minHeight: 2)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeDocumentUploadSectionForProgress(ProjectModel project) {
    final bool canUpload = [
      'In Progress',
      'Details Submitted - Pending Office Review',
      'Awaiting User Payment',
      'Payment Proposal Sent',
    ].contains(project.status);
    if (!canUpload) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Upload Stage Documents (For Office)'),
            //  مرحلة 0 لا يوجد لها ملف
            _buildUploadButtonForProgressStage(
              project,
              1,
              'architectural_file',
              _officeProgressFileMapping[1]!['formField']!,
              _progressStageLabels[1],
            ),
            _buildUploadButtonForProgressStage(
              project,
              2,
              'structural_file',
              _officeProgressFileMapping[2]!['formField']!,
              _progressStageLabels[2],
            ),
            _buildUploadButtonForProgressStage(
              project,
              3,
              'electrical_file',
              _officeProgressFileMapping[3]!['formField']!,
              _progressStageLabels[3],
            ),
            _buildUploadButtonForProgressStage(
              project,
              4,
              'mechanical_file',
              _officeProgressFileMapping[4]!['formField']!,
              _progressStageLabels[4],
            ),
            _buildUploadButtonForProgressStage(
              project,
              5,
              'document_2d',
              _officeProgressFileMapping[5]!['formField']!,
              _progressStageLabels[5],
            ), //  الـ 2D النهائي
            const SizedBox(height: 10),
            _buildSectionTitle('Upload Optional 3D Model (Office)'),
            _buildUploadButtonForProgressStage(
              project,
              -1,
              'document_3d',
              'optional3dFile',
              'Optional 3D Model',
            ), // -1 لتمييزه
            if (_isOfficeUploadingFile)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: LinearProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButtonForProgressStage(
    ProjectModel project,
    int stageIndexForLabel,
    String documentDbKey,
    String formFieldName,
    String buttonLabel,
  ) {
    String? currentFilePath = _getProjectDocumentPath(
      documentDbKey,
    ); // دالة مساعدة لجلب المسار
    bool fileExists = currentFilePath != null && currentFilePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                fileExists
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: fileExists ? Colors.green : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: fileExists ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (fileExists)
            TextButton.icon(
              icon: Icon(
                Icons.visibility_outlined,
                size: 16,
                color: AppColors.accent.withOpacity(0.8),
              ),
              label: Text(
                "View",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accent.withOpacity(0.8),
                ),
              ),
              onPressed: () async {
                String fullUrl =
                    '${Constants.baseUrl}/documents/archdocument'; //  تكوين الـ URL
                logger.i("Attempting to open document link: $fullUrl");

                final uri = Uri.parse(fullUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  ); //  يفتح في المتصفح/التطبيق المناسب
                } else {
                  logger.e('Could not launch $fullUrl');
                  if (mounted) {
                    // تأكدي أن mounted متاح إذا كنتِ داخل State
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open the document link.'),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
              ),
            )
          else
            const SizedBox(width: 60), //  للمحافظة على التنسيق

          ElevatedButton(
            onPressed:
                _isOfficeUploadingFile
                    ? null
                    : () => _handleOfficeUploadFile(
                      documentDbKey,
                      formFieldName,
                      buttonLabel,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  fileExists ? Colors.orange.shade700 : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: Text(fileExists ? "Re-upload" : "Upload"),
          ),
        ],
      ),
    );
  }

  String? _getProjectDocumentPath(String dbKey) {
    //  دالة مساعدة لجلب مسار الملف من _project
    if (_project == null) return null;
    switch (dbKey) {
      case 'agreement_file':
        return _project!.agreementFile;
      case 'license_file':
        return _project!.licenseFile;
      case 'architectural_file':
        return _project!.architecturalfile;
      case 'structural_file':
        return _project!.structuralfile;
      case 'electrical_file':
        return _project!.electricalfile;
      case 'mechanical_file':
        return _project!.mechanicalfile;
      case 'document_2d':
        return _project!.document2D;
      case 'document_3d':
        return _project!.document3D;
      default:
        return null;
    }
  }

  // === ويدجتس فرعية للأقسام الخاصة بالمستخدم ===
  Widget _buildUserPaymentActionSection(ProjectModel project) {
    final bool canMakePayment =
        (project.status == 'Payment Proposal Sent' ||
            project.status == 'Awaiting User Payment') &&
        project.proposedPaymentAmount != null &&
        project.proposedPaymentAmount! > 0;
    final bool isPaid =
        project.paymentStatus?.toLowerCase() == 'paid' ||
        ['In Progress', 'Completed'].contains(project.status);
    if (!canMakePayment && !isPaid) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Payment Information'),
            _buildInfoRow(
              'Proposed Amount:',
              project.proposedPaymentAmount != null
                  ? currencyFormat.format(project.proposedPaymentAmount!)
                  : 'N/A',
              icon: Icons.monetization_on_outlined,
            ),
            if (project.paymentNotes != null &&
                project.paymentNotes!.isNotEmpty)
              _buildInfoRow(
                'Office Notes on Payment:',
                project.paymentNotes,
                icon: Icons.sticky_note_2_outlined,
              ),
            _buildInfoRow(
              'Payment Status:',
              project.paymentStatus ?? 'Pending',
              icon: Icons.credit_score_outlined,
            ),
            const SizedBox(height: 12),
            if (canMakePayment && !isPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 15),
                  ), // تصغير الخط
                  onPressed: _handleMakePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ), // تعديل الحشو
                ),
              )
            else if (isPaid)
              Center(
                child: Chip(
                  label: Text(
                    "Payment Confirmed",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green.shade600,
                  avatar: Icon(Icons.price_check_rounded, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //  ✅✅✅ قسم عرض التقدم للمستخدم ✅✅✅
  Widget _buildUserProgressViewSection(ProjectModel project) {
    if ((project.progressStage ?? -1) < 0 && project.status != 'Completed') {
      //  لا تعرض شيئاً إذا لم يبدأ التقدم بعد (باستثناء إذا اكتمل)
      //  أو إذا كانت الحالة لا تشير إلى أن العمل قد بدأ (مثل Pending Office Approval)
      if ([
        'Pending Office Approval',
        'Office Approved - Awaiting Details',
        'Office Rejected',
        'Cancelled',
      ].contains(project.status)) {
        return const SizedBox.shrink();
      }
    }

    int currentStage = project.progressStage ?? 0;
    if (currentStage < 0) currentStage = 0; //  إذا كان null، اعتبره 0
    if (currentStage >= _progressStageLabels.length) {
      currentStage = _progressStageLabels.length - 1;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Project Progress'),
            if (project.status == 'Completed')
              Center(
                child: Chip(
                  label: Text(
                    "Project Completed!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  avatar: Icon(Icons.celebration_rounded, color: Colors.white),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  value: (currentStage / (_progressStageLabels.length - 1)),
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 10, //  جعل الشريط أعرض
                ),
              ),
              Center(
                child: Text(
                  'Current Stage: ${_progressStageLabels[currentStage]} (${((currentStage / (_progressStageLabels.length - 1)) * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              //  عرض قائمة بالمراحل والملفات المرفوعة (للقراءة فقط)
              Text(
                "Stages & Documents:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              for (
                int i = 1;
                i < _progressStageLabels.length;
                i++
              ) //  ابدأ من المرحلة 1 (بعد Kick-off)
                _buildUserProgressStageItem(
                  project,
                  i,
                  _officeProgressFileMapping[i]!['dbField']!,
                  _progressStageLabels[i],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserProgressStageItem(
    ProjectModel project,
    int stageNumber,
    String documentDbKey,
    String stageLabel,
  ) {
    String? filePath = _getProjectDocumentPath(documentDbKey);
    bool stageCompleted = (project.progressStage ?? 0) >= stageNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(
            stageCompleted
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color:
                stageCompleted ? Colors.green.shade600 : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stageLabel,
              style: TextStyle(
                fontSize: 13.5,
                color:
                    stageCompleted
                        ? AppColors.textPrimary
                        : Colors.grey.shade600,
              ),
            ),
          ),
          if (filePath != null && filePath.isNotEmpty)
            TextButton.icon(
              icon: Icon(
                Icons.download_for_offline_outlined,
                size: 16,
                color: AppColors.accent.withOpacity(0.8),
              ),
              label: Text(
                "View/Download",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accent.withOpacity(0.8),
                ),
              ),
              onPressed: () async {
                //  ✅ جعلها async
                // ignore: unused_local_variable
                String fullUrl =
                    '${Constants.baseUrl}/documents/archdocument'; //  تكوين الـ URL
                logger.i("Attempting to open document link: $fullUrl");

                final uri = Uri.parse(fullUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  ); //  يفتح في المتصفح/التطبيق المناسب
                } else {
                  logger.e('Could not launch $fullUrl');
                  if (mounted) {
                    // تأكدي أن mounted متاح إذا كنتِ داخل State
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open the document link.'),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
              ),
            )
          else if (stageCompleted) //  اكتملت المرحلة ولكن لا يوجد ملف (قد لا يكون لكل مرحلة ملف إلزامي)
            Text(
              "(Completed)",
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              "(Pending)",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUser3DViewSection(ProjectModel project) {
    // ... (نفس الكود)
    //  يعرض فقط إذا كان المستخدم هو المالك وهناك ملف 3D (الذي يرفعه المكتب كـ optional)
    //  أو إذا كانت خاصية Convert to 3D متاحة
    bool canConvert = true;

    if ((project.document3D == null || project.document3D!.isEmpty) &&
        // ignore: dead_code
        !canConvert) {}

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('3D Visualization'),
            if (project.document3D != null && project.document3D!.isNotEmpty)
              _buildDocumentItem(
                'View Office 3D Model:',
                project.document3D,
                'document_3d',
              ),
            if (canConvert)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    //  تغيير إلى ElevatedButton
                    icon: const Icon(
                      Icons.threed_rotation_outlined,
                      size: 20,
                    ), //  تغيير الأيقونة
                    label: const Text(
                      'Convert to Interactive 3D (Planner 5D)',
                      style: TextStyle(fontSize: 13.5),
                    ), // تعديل النص
                    onPressed: _handleView3DViaPlanner5D,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(
    String label,
    String? filePath,
    String documentKey, {
    bool canUserUpload = false,
  }) {
    bool isOfficeViewing =
        _sessionUserType?.toLowerCase() == 'office' &&
        _project?.officeId == _currentUser?.id;
    bool isUserViewingAndOwner =
        _sessionUserType?.toLowerCase() == 'individual' &&
        _project?.userId == _currentUser?.id;

    //  تحديد إذا كان يمكن رفع هذا النوع من الملفات بواسطة الطرف الحالي
    bool canCurrentActorUploadThisDocType = false;
    String formFieldName = documentKey; //  افتراضي

    if (isUserViewingAndOwner && canUserUpload) {
      //  المستخدم يرفع (فقط license و agreement)
      if (documentKey == 'licensefile') {
        canCurrentActorUploadThisDocType = true;
        formFieldName = 'licenseFile';
      } else if (documentKey == 'agreement_file') {
        // المستخدم رفع الاتفاقية في شاشة سابقة
        canCurrentActorUploadThisDocType = false; // لا يسمح بإعادة الرفع من هنا
      }
    } else if (isOfficeViewing) {
      // المكتب يرفع
      final officeUploadableDocs = [
        'architectural_file',
        'structural_file',
        'electrical_file',
        'mechanical_file',
        'document_2d',
        'document_3d',
      ];
      if (officeUploadableDocs.contains(documentKey)) {
        canCurrentActorUploadThisDocType = true;
        //  تحديد formFieldName للمكتب
        if (documentKey == 'architectural_file') {
          formFieldName = 'architecturalFile';
        } else if (documentKey == 'structural_file') {
          formFieldName = 'structuralFile';
        } else if (documentKey == 'electrical_file') {
          formFieldName = 'electricalFile';
        } else if (documentKey == 'mechanical_file') {
          formFieldName = 'mechanicalFile';
        } else if (documentKey == 'document_2d') {
          formFieldName = 'final2dFile';
        } else if (documentKey == 'document_3d') {
          formFieldName = 'optional3dFile';
        }
      }
    }

    // حالة المشروع التي تسمح بالرفع
    bool canUploadBasedOnStatus = false;
    if (isUserViewingAndOwner && canUserUpload) {
      canUploadBasedOnStatus = [
        'Office Approved - Awaiting Details',
      ].contains(_project?.status ?? '');
    } else if (isOfficeViewing && canCurrentActorUploadThisDocType) {
      canUploadBasedOnStatus = [
        'In Progress',
        'Details Submitted - Pending Office Review',
        'Awaiting User Payment',
        'Payment Proposal Sent',
      ].contains(_project?.status ?? '');
    }

    if (filePath == null || filePath.isEmpty) {
      if (canCurrentActorUploadThisDocType && canUploadBasedOnStatus) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              Icon(
                Icons.attach_file_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    _isOfficeUploadingFile
                        ? null
                        : () => _handleOfficeUploadFile(
                          documentKey,
                          formFieldName,
                          label.replaceAll(':', ''),
                        ), // استخدام _isOfficeUploadingFile كحالة تحميل عامة للملفات
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size(70, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Upload',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return _buildInfoRow(
        label,
        'Not Uploaded',
        icon: Icons.file_copy_rounded,
        onLinkTap: null,
      );
    }
    return _buildInfoRow(
      label,
      filePath.split('/').last,
      icon: Icons.visibility_outlined, // أيقونة للعرض
      isLink: true,
      onLinkTap: () async {
        String fullUrl =
            '${Constants.baseUrl}/documents/archdocument'; //  تكوين الـ URL
        logger.i("Attempting to open document link: $fullUrl");

        final uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          ); //  يفتح في المتصفح/التطبيق المناسب
        } else {
          logger.e('Could not launch $fullUrl');
          if (mounted) {
            // تأكدي أن mounted متاح إذا كنتِ داخل State
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open the document link.')),
            );
          }
        }
      },
    );
  }
}
