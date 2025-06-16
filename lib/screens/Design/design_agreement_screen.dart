// screens/DesignAgreementScreen.dart
import 'dart:io';
import 'package:buildflow_frontend/models/Basic/project_model.dart';
import 'package:buildflow_frontend/models/Basic/user_model.dart'; // تأكدي من المسار الصحيح
import '/services/create/project_service.dart';
import '/services/create/user_update_service.dart'; // تأكدي من المسار الصحيح
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'project_description.dart';
import 'dart:typed_data'; // لـ Uint8List

import 'app_strings.dart'; // تأكدي من وجود هذا أو استبدلي النصوص مباشرة
// import 'project_description.dart'; //  شاشة الوصف و Submit النهائي (أو ما يعادلها)
// تأكدي من استيراد شاشة تفاصيل المشروع إذا كانت مختلفة
// import 'project_details_screen.dart'; // افترضت أن ProjectDetailsScreen هي شاشة العرض النهائية

final Logger logger = Logger();

class DesignAgreementScreen extends StatefulWidget {
  const DesignAgreementScreen({super.key, required this.projectId});
  final int projectId;

  @override
  State<DesignAgreementScreen> createState() => _DesignAgreementScreenState();
}

class _DesignAgreementScreenState extends State<DesignAgreementScreen> {
  final Map<String, TextEditingController> _controllers = {};

  // للملفات
  String? _uploadedAgreementFilePath; // يخزن المسار/الاسم من السيرفر بعد الرفع
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;

  bool _isLoadingInitialData = true; // لتحميل البيانات الأولية
  bool _isSavingStepData = false; // لحفظ بيانات الخطوة الحالية
  bool _isSubmittingFinal = false; // للـ Submit النهائي
  // bool _isUploadingFile = false; //  تم استبداله بـ _isSavingStepData لعملية الرفع

  int _currentStep = 0;

  ProjectModel? _currentProjectData;
  UserModel? _currentUserData;

  final ProjectService _projectService = ProjectService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInitialData();
    for (var controller in _controllers.values) {
      controller.addListener(() => setState(() {}));
    }
  }

  void _initControllers() {
    // خطوة 0: معلومات المستخدم
    _controllers['userName'] = TextEditingController();
    _controllers['userIdNumber'] = TextEditingController();
    _controllers['userAddress'] = TextEditingController();
    _controllers['userPhone'] = TextEditingController();
    _controllers['userBankAccount'] = TextEditingController();
    // خطوة 1: معلومات الأرض
    _controllers['landArea'] = TextEditingController();
    _controllers['plotNumber'] = TextEditingController();
    _controllers['basinNumber'] = TextEditingController();
    _controllers['landLocation'] = TextEditingController();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingInitialData = true);
    try {
      // جلب بيانات المستخدم والمشروع بالتوازي
      final results = await Future.wait([
        _userService.getCurrentUserDetails(),
        _projectService.getProjectDetailscreate(widget.projectId),
      ]);

      if (mounted) {
        setState(() {
          _currentUserData = results[0] as UserModel;
          _currentProjectData =
              results[1]
                  as ProjectModel; // تأكدي أن getProjectDetails ترجع ProjectModel
          _populateControllersForCurrentStep();
          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      logger.e("Error loading initial data: $e");
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load initial data: ${e.toString()}'),
          ),
        );
        // يمكنكِ هنا توجيه المستخدم للخارج إذا فشل تحميل البيانات الأساسية
        // Navigator.of(context).pop();
      }
    }
  }

  void _populateControllersForCurrentStep() {
    if (!mounted) return;
    // مسح أي بيانات سابقة من الكونترولرز قبل التعبئة (مهم عند التنقل بين الخطوات)
    // _controllers.forEach((key, controller) { controller.clear(); }); // أو عند _initControllers

    // تعبئة حقول المستخدم (لجميع الخطوات، لكنها تظهر في الخطوة 0)
    if (_currentUserData != null) {
      _controllers['userName']!.text =
          _currentUserData!.name; // UserModel.name ليس nullable
      _controllers['userIdNumber']!.text = _currentUserData!.idNumber ?? '';
      _controllers['userAddress']!.text =
          _currentUserData!.location ??
          ''; // UserModel.location هو عنوان المستخدم
      _controllers['userPhone']!.text =
          _currentUserData!.phone; // UserModel.phone ليس nullable
      _controllers['userBankAccount']!.text =
          _currentUserData!.bankAccount ?? '';
    }

    // تعبئة حقول المشروع (لجميع الخطوات، لكنها تظهر في الخطوة 1 و 2)
    if (_currentProjectData != null) {
      _controllers['landArea']!.text =
          _currentProjectData!.landArea?.toString() ?? '';
      _controllers['plotNumber']!.text =
          _currentProjectData!
              .plotNumber!; // ProjectModel.plotNumber ليس nullable (حسب تعديلنا الأخير)
      _controllers['basinNumber']!.text = _currentProjectData!.basinNumber!;
      _controllers['landLocation']!.text = _currentProjectData!.landLocation!;

      if (_currentStep == 2) {
        setState(() {
          _uploadedAgreementFilePath =
              _currentProjectData!.agreementFile; // من موديل المشروع
          _pickedFileBytes = null;
          _pickedFileName = null;
        });
      }
    }
  }

  bool get _isCurrentStepFormValid {
    switch (_currentStep) {
      case 0: // User Info
        return _controllers['userName']!.text.isNotEmpty &&
            _controllers['userIdNumber']!.text.isNotEmpty &&
            _controllers['userAddress']!.text.isNotEmpty &&
            _controllers['userPhone']!.text.isNotEmpty &&
            _controllers['userBankAccount']!.text.isNotEmpty;
      case 1: // Land Info
        return _controllers['landArea']!.text.isNotEmpty &&
            _controllers['plotNumber']!.text.isNotEmpty &&
            _controllers['basinNumber']!.text.isNotEmpty &&
            _controllers['landLocation']!.text.isNotEmpty;
      case 2: // Supporting Docs
        // إذا كان هناك ملف مرفوع سابقاً أو ملف جديد تم اختياره
        return _pickedFileName != null ||
            (_uploadedAgreementFilePath != null &&
                _uploadedAgreementFilePath!.isNotEmpty);
      default:
        return false;
    }
  }

  // دالة لحفظ بيانات الخطوة الحالية والانتقال للخطوة التالية أو الـ Submit
  Future<void> _handleNextStepOrSubmit() async {
    logger.i(
      "Attempting to handle next step or submit. Current step: $_currentStep",
    );
    if (!_isCurrentStepFormValid) {
      logger.w("Form is NOT valid for current step: $_currentStep");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields for the current step'),
        ),
      );
      return;
    }
    logger.i("Form IS valid for current step: $_currentStep");

    if (_isSavingStepData || _isSubmittingFinal) {
      logger.i("Action already in progress. Returning.");
      return; // منع الضغط المتكرر
    }

    setState(() => _isSavingStepData = true);

    bool stepSaveSuccess = false;
    Map<String, dynamic> dataToSave = {};

    try {
      if (_currentStep == 0) {
        // حفظ معلومات المستخدم
        dataToSave = {
          'name': _controllers['userName']!.text,
          'id_number': _controllers['userIdNumber']!.text,
          'location':
              _controllers['userAddress']!
                  .text, // يطابق 'location' في UserModel
          'phone': _controllers['userPhone']!.text,
          'bank_account': _controllers['userBankAccount']!.text,
        };
        final updatedUser = await _userService.updateMyProfile(dataToSave);
        if (mounted) setState(() => _currentUserData = updatedUser);
        logger.i("User profile data updated for step 0.");
        stepSaveSuccess = true;
      } else if (_currentStep == 1) {
        // حفظ معلومات الأرض في المشروع
        dataToSave = {
          'land_area': double.tryParse(_controllers['landArea']!.text),
          'plot_number': _controllers['plotNumber']!.text,
          'basin_number': _controllers['basinNumber']!.text,
          'land_location': _controllers['landLocation']!.text,
        };
        final updatedProject = await _projectService.updateProjectDetails(
          widget.projectId,
          dataToSave,
        );
        if (mounted) setState(() => _currentProjectData = updatedProject);
        logger.i(
          "Land info data saved for project ${widget.projectId} for step 1.",
        );
        stepSaveSuccess = true;
      } else if (_currentStep == 2) {
        // خطوة رفع الملفات، فقط نتحقق من وجود ملف
        stepSaveSuccess = true; // سنقوم بالرفع الفعلي عند الـ Submit النهائي
      }

      if (stepSaveSuccess && mounted) {
        if (_currentStep < 2) {
          setState(() {
            _currentStep++;
            _populateControllersForCurrentStep(); // تعبئة بيانات الخطوة الجديدة
          });
        } else {
          logger.i("Last step, calling _submitFinalForm()");

          // وصلنا للخطوة الأخيرة، وتم التحقق من صلاحية النموذج (وجود ملف)
          await _submitFinalForm(); // تغيير إلى await
        }
      }
    } catch (e) {
      logger.e("Error saving data for step $_currentStep: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingStepData = false);
    }
  }

  void _previousStep() {
    // لا تحتاج لـ async إذا لم يكن هناك حفظ عند الرجوع
    if (_isSavingStepData || _isSubmittingFinal) return;
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _populateControllersForCurrentStep();
      });
    }
  }

  Future<void> _pickPDF() async {
    if (_isSavingStepData || _isSubmittingFinal) {
      return; // منع اختيار ملف أثناء عملية أخرى
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result != null) {
        PlatformFile file = result.files.single;
        if (file.size > 5 * 1024 * 1024) {
          // 5MB
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 5MB')),
            );
          }
          return;
        }

        Uint8List? fileBytes;
        if (kIsWeb) {
          fileBytes = file.bytes;
        } else {
          final mobileFile = File(file.path!);
          fileBytes = await mobileFile.readAsBytes();
        }

        if (fileBytes != null) {
          setState(() {
            _pickedFileBytes = fileBytes;
            _pickedFileName = file.name;
            _uploadedAgreementFilePath = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF Selected: $_pickedFileName')),
            );
          }
        } else {
          throw Exception("Could not read file bytes.");
        }
      }
    } catch (e) {
      logger.e("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick file.')));
      }
    }
  }

  // داخل _DesignAgreementScreenState

  Future<void> _submitFinalForm() async {
    logger.i(
      "_submitFinalForm CALLED. _isCurrentStepFormValid: $_isCurrentStepFormValid (for step 2)",
    );
    // التحقق من صلاحية النموذج للخطوة الحالية (خطوة الملف) يجب أن يتم هنا أيضاً
    // لأن _handleNextStepOrSubmit قد لا تكون هي التي تستدعي _submitFinalForm مباشرة دائماً
    // أو للتأكيد الإضافي.
    if (!_isCurrentStepFormValid) {
      //  أعدت التحقق هنا
      logger.w(
        "_submitFinalForm: PDF file is missing (checked via _isCurrentStepFormValid).",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the agreement PDF.')),
      );
      // لا نضبط _isSubmittingFinal إلى false هنا لأننا لم نضبطها إلى true بعد
      return;
    }

    if (_isSubmittingFinal) {
      //  تم إزالة _isSavingStepData من هذا الشرط
      logger.i(
        "_submitFinalForm: Submission already in progress (outer check). Returning.",
      );
      return;
    }
    setState(() => _isSubmittingFinal = true);

    logger.i("Attempting final submission for project ${widget.projectId}...");
    String? finalAgreementFilePathOnServer =
        _uploadedAgreementFilePath; //  كان اسمه _uploadedAgreementFilePathDB

    try {
      //  Try block رئيسي يغلف كل العملية
      // 1. رفع الملف إذا تم اختيار ملف جديد ولم يتم رفعه بعد
      if (_pickedFileBytes != null && _pickedFileName != null) {
        logger.i(
          "Uploading new agreement file: $_pickedFileName for project ${widget.projectId}",
        );
        try {
          finalAgreementFilePathOnServer = await _projectService
              .uploadProjectAgreement(
                widget.projectId,
                _pickedFileBytes!,
                _pickedFileName!,
              );

          if (finalAgreementFilePathOnServer == null) {
            logger.e(
              "File path not returned after upload from service (uploadProjectAgreement).",
            );
            throw Exception("File path not returned after upload.");
          }
          logger.i(
            "File uploaded via service, path on server: $finalAgreementFilePathOnServer",
          );
          if (mounted) {
            setState(() {
              _uploadedAgreementFilePath =
                  finalAgreementFilePathOnServer; //  تحديث الاسم هنا
              _pickedFileBytes = null;
              _pickedFileName = null;
            });
          }
        } catch (e, s) {
          //  إمساك الخطأ هنا وتفاصيله
          logger.e(
            "Error during _projectService.uploadProjectAgreement",
            error: e,
            stackTrace: s,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload agreement PDF: ${e.toString()}',
                ),
              ),
            );
          }
          //  لا تقم بـ return هنا مباشرة، دع الـ finally الرئيسي يتعامل مع _isSubmittingFinal
          rethrow; //  أعد رمي الخطأ ليتم الإمساك به بواسطة الـ catch block الخارجي
        }
      } else if (_uploadedAgreementFilePath == null ||
          _uploadedAgreementFilePath!.isEmpty) {
        logger.w(
          "_submitFinalForm: No file selected and no previous file exists. PDF is required.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agreement PDF is required for submission.'),
            ),
          );
        }
        //  لا تقم بـ return هنا مباشرة، دع الـ finally الرئيسي يتعامل مع _isSubmittingFinal
        throw Exception(
          "Agreement PDF is required.",
        ); //  ارمي خطأً ليتم الإمساك به
      }

      // 2. استدعاء API الـ Submit النهائي
      logger.i(
        "Calling _projectService.submitFinalProjectDetails for project ${widget.projectId} with agreement: $finalAgreementFilePathOnServer",
      );
      try {
        await _projectService.submitFinalProjectDetails(
          widget.projectId,
          finalAgreementFilePathFromUpload: finalAgreementFilePathOnServer,
        );
        logger.i(
          "Final project details submitted successfully for project ${widget.projectId}",
        );
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text(
        //         'Project details submitted successfully! Waiting for office review.',
        //       ),
        //     ),
        //   );
        //   // Navigator.of(context).popUntil((route) => route.isFirst);
        // }
        // داخل _submitFinalForm، بعد SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Project details submitted successfully! Waiting for office review.',
              ),
              backgroundColor: Colors.green, //  لون للنجاح
            ),
          );

          // ✅✅✅ التعديل هنا ✅✅✅
          Navigator.pushReplacement(
            //  استبدال الشاشة الحالية
            context,
            MaterialPageRoute(
              // افترض أن ProjectDetailsScreen تتوقع projectId
              // إذا لم تكن تتوقعه، يمكنكِ إزالة المعامل
              builder:
                  (context) => ProjectDescriptionScreen(
                    projectId: widget.projectId,
                    // تمرير البيانات الحالية
                  ),
            ),
          );
        }
      } catch (e, s) {
        // إمساك الخطأ هنا وتفاصيله
        logger.e(
          "Error in final submission API call (submitFinalProjectDetails)",
          error: e,
          stackTrace: s,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Final submission failed: ${e.toString()}')),
          );
        }
        rethrow; //  أعد رمي الخطأ ليتم الإمساك به بواسطة الـ catch block الخارجي
      }
    } catch (e) {
      //  Catch block خارجي لأي أخطاء أخرى في التدفق
      logger.e("An error occurred in _submitFinalForm logic", error: e);
      //  الرسالة للمستخدم قد تكون عُرضت بالفعل من الـ catch blocks الداخلية
      //  إذا لم تكن، يمكنكِ عرض رسالة عامة هنا
    } finally {
      logger.i(
        "_submitFinalForm finally block executing. Current _isSubmittingFinal: $_isSubmittingFinal",
      );
      if (mounted) {
        setState(() => _isSubmittingFinal = false);
        logger.i("_submitFinalForm: _isSubmittingFinal set to false.");
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildStepProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == _currentStep;
        bool isCompleted = index < _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 8,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColors.accent
                      : isActive
                      ? AppColors.primary
                      : AppColors.card.withAlpha(
                        (0.5 * 255).round(),
                      ), // لون باهت للخطوات غير النشطة
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    if (_isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_currentStep) {
      case 0:
        return _buildUserInfoSection();
      case 1:
        return _buildLandInfoSection();
      case 2:
        return _buildSupportingDocsSection();
      default:
        return Container();
    }
  }

  Widget _buildUserInfoSection() {
    return _buildSectionCard(
      title: AppStrings.userInfo, // تأكدي من تعريف هذه النصوص
      color: AppColors.accent,
      children: [
        _buildResponsiveRow([
          _buildField(
            _controllers['userName']!,
            AppStrings.name,
            readOnly: _isSavingStepData,
          ),
          _buildField(
            _controllers['userIdNumber']!,
            AppStrings.idNumber,
            readOnly: _isSavingStepData,
          ),
        ]),
        const SizedBox(height: 12),
        _buildResponsiveRow([
          _buildField(
            _controllers['userAddress']!,
            AppStrings.address,
            readOnly: _isSavingStepData,
          ),
          _buildField(
            _controllers['userPhone']!,
            AppStrings.phone,
            keyboardType: TextInputType.phone,
            readOnly: _isSavingStepData,
          ),
        ]),
        const SizedBox(height: 12),
        _buildResponsiveRow([
          _buildField(
            _controllers['userBankAccount']!,
            AppStrings.bankAccount,
            readOnly: _isSavingStepData,
          ),
          //  يمكن إضافة حقل فارغ هنا إذا أردتِ الحفاظ على التنسيق إذا كان هناك حقل واحد فقط
          // Expanded(child: SizedBox()),
        ]),
      ],
    );
  }

  Widget _buildLandInfoSection() {
    return _buildSectionCard(
      title: AppStrings.landInfo,
      color: AppColors.accent,
      children: [
        _buildField(
          _controllers['landArea']!,
          AppStrings.area,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          readOnly: _isSavingStepData,
        ),
        Row(
          children: [
            Expanded(
              child: _buildField(
                _controllers['plotNumber']!,
                AppStrings.plotNumber,
                readOnly: _isSavingStepData,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                _controllers['basinNumber']!,
                AppStrings.basinNumber,
                readOnly: _isSavingStepData,
              ),
            ),
          ],
        ),
        _buildField(
          _controllers['landLocation']!,
          AppStrings.areaName,
          readOnly: _isSavingStepData,
        ), //  كان areaName
      ],
    );
  }

  Widget _buildSupportingDocsSection() {
    // ... (الكود من ردك السابق، مع تعديل بسيط لعرض اسم الملف المختار)
    // ... وتعديل onPressed لزر الحذف
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.grey.withAlpha((0.3 * 255).round()),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.supportingDocs, // "Agreement Document"
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black45,
                ),
                onPressed:
                    _isSavingStepData || _isSubmittingFinal ? null : _pickPDF,
                icon:
                    _isSavingStepData &&
                            _pickedFileBytes !=
                                null //  إذا كنا نرفع الملف حالياً (لم نضف حالة isUploadingFile بعد)
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(
                          Icons.attach_file,
                          color: Colors.white,
                          size: 22,
                        ),
                label: Text(
                  (_isSavingStepData && _pickedFileBytes != null)
                      ? 'Uploading...'
                      : AppStrings.uploadPdf, // "Upload Agreement PDF"
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Text(
                'Please upload the design agreement PDF (max 5MB).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_pickedFileName != null) //  إذا تم اختيار ملف جديد
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: $_pickedFileName',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      tooltip: 'Clear Selection',
                      onPressed:
                          _isSavingStepData || _isSubmittingFinal
                              ? null
                              : () {
                                setState(() {
                                  _pickedFileBytes = null;
                                  _pickedFileName = null;
                                  // لا نغير _uploadedAgreementFilePath هنا إلا إذا أردنا حذف الملف المرفوع سابقاً
                                });
                              },
                    ),
                  ],
                ),
              )
            else if (_uploadedAgreementFilePath != null &&
                _uploadedAgreementFilePath!
                    .isNotEmpty) //  إذا كان هناك ملف مرفوع سابقاً
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.file_present_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Uploaded: ${_uploadedAgreementFilePath!.split('/').last}', // عرض اسم الملف فقط
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      //  زر لحذف الملف المرفوع سابقاً (يحتاج لدعم من الـ backend)
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      tooltip: 'Remove Uploaded File (Will require re-upload)',
                      onPressed:
                          _isSavingStepData || _isSubmittingFinal
                              ? null
                              : () {
                                // هنا يمكنكِ استدعاء API لحذف الملف من السيرفر وتحديث UI
                                // حالياً، فقط سنمسحه من الـ state المحلي ليتمكن المستخدم من رفع ملف جديد
                                setState(() {
                                  _uploadedAgreementFilePath = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Previous file cleared. Please upload a new one if needed.',
                                    ),
                                  ),
                                );
                              },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // الـ AppBar المخصص موجود بالأسفل
      body: SafeArea(
        child: Column(
          children: [
            const _CustomAppBar(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStepProgressIndicator(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        (_currentStep > 0 &&
                                !_isSavingStepData &&
                                !_isSubmittingFinal)
                            ? _previousStep
                            : null,
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_isCurrentStepFormValid)
                              ? AppColors.accent
                              : AppColors.primary.withAlpha(
                                (0.5 * 255).round(),
                              ),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        (_isCurrentStepFormValid &&
                                !_isSavingStepData &&
                                !_isSubmittingFinal)
                            ? _handleNextStepOrSubmit
                            : null,
                    child:
                        (_isSavingStepData || _isSubmittingFinal)
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Text(_currentStep == 2 ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      color: AppColors.card,
      elevation: 3, // تقليل الـ elevation قليلاً
      margin: const EdgeInsets.only(bottom: 20), // تقليل الهامش السفلي
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // تقليل الـ radius قليلاً
      shadowColor: AppColors.shadow.withAlpha((0.2 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ), // تقليل حجم الخط
            ),
            const SizedBox(height: 12), // تقليل المسافة
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false, //  معامل جديد
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ), // زيادة الـ padding العمودي قليلاً
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly, // تطبيق خاصية القراءة فقط
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary.withAlpha((0.8 * 255).round()),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // تقليل الـ radius
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            //  تحديد شكل الحدود عندما يكون الحقل مفعلاً
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            // تحديد شكل الحدود عند التركيز
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
          filled: true,
          fillColor:
              readOnly
                  ? Colors.grey.shade200
                  : AppColors.background, // لون مختلف للقراءة فقط
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ), // تعديل الـ padding الداخلي
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          //  تعديل الـ breakpoint
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // محاذاة العناصر للأعلى
            children:
                children
                    .map(
                      (child) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                          ), // تقليل الـ padding الأفقي
                          child: child,
                        ),
                      ),
                    )
                    .toList(),
          );
        } else {
          return Column(children: children);
        }
      },
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.15 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
              "Pre-Submission Requirements", // يمكنكِ تغيير هذا العنوان ليكون أكثر عمومية
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // للموازنة مع زر الرجوع
        ],
      ),
    );
  }
}

class ProjectDetailsScreen extends StatelessWidget {
  final int? projectId; // قد تحتاجين لتمرير projectId هنا
  const ProjectDetailsScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectId != null
              ? 'Project ID: $projectId Details'
              : 'Project Submitted',
        ),
      ),
      body: Center(
        child: Text(
          projectId != null
              ? 'Details for project ID $projectId will be shown here.'
              : 'Project information submitted successfully and is under review!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
