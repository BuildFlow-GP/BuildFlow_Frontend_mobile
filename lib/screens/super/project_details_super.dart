// screens/supervision/project_supervision_details_screen.dart
import 'dart:io';
import 'package:buildflow_frontend/models/Basic/project_model.dart';
import 'package:buildflow_frontend/models/Basic/user_model.dart';
import 'package:buildflow_frontend/models/create/project_design_model.dart'; //  ✅  مهم لهذا الملف
import 'package:buildflow_frontend/services/create/project_service.dart'; //  ✅
import 'package:buildflow_frontend/services/create/user_update_service.dart'; // ✅
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:buildflow_frontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/session.dart';
import '../Profiles/office_profile.dart';
// import '../ReadonlyProfiles/office_readonly_profile.dart'; //  قد لا نحتاجه إذا استخدمنا OfficeProfileScreen
//  شاشات للانتقال إليها
import '../Design/payment_screen.dart';
import 'select_company_supervision.dart'; //  ✅  سنحتاجه لزر الدفع

final Logger logger = Logger(
  printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5, lineLength: 120),
);

// ===========================================================================
//  الويدجتس المستخلصة (مؤقتاً هنا، يمكنكِ نقلها لملفات منفصلة)
// ===========================================================================

// --- دوال مساعدة للويدجتس المستخلصة ---
Widget _buildSharedInfoRow(String label, String? value, {IconData? icon}) {
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
                    color: AppColors.textSecondary.withAlpha(
                      (0.8 * 255).round(),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSharedSectionTitle(
  String title, {
  Widget? trailing,
  BuildContext? context,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}
// --- نهاية الدوال المساعدة ---

// 1. ويدجت عرض تفاصيل التصميم (للقراءة فقط في هذه الشاشة)
class ReusableDesignDetailsViewWidget extends StatelessWidget {
  final ProjectDesignModel? design; //  ✅  تستقبل ProjectDesignModel مباشرة
  // final VoidCallback? onEditDetails; //  عادة لا يوجد تعديل تصميم في شاشة الإشراف
  // final bool canUserEdit; //  عادة false هنا

  const ReusableDesignDetailsViewWidget({
    super.key,
    required this.design,
    // this.onEditDetails,
    // this.canUserEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    );
    if (design == null) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSharedSectionTitle('Design Specifications'),
              const Text(
                "No design details available for this project.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle(
              'Design Specifications (View Only)',
              context: context,
            ),
            _buildSharedInfoRow(
              'Floors:',
              design!.floorCount?.toString() ?? 'N/A',
              icon: Icons.stairs_outlined,
            ),
            _buildSharedInfoRow(
              'Bedrooms:',
              design!.bedrooms?.toString() ?? 'N/A',
              icon: Icons.bed_outlined,
            ),
            _buildSharedInfoRow(
              'Bathrooms:',
              design!.bathrooms?.toString() ?? 'N/A',
              icon: Icons.bathtub_outlined,
            ),
            //  أضيفي باقي حقول design هنا بنفس النمط
            if (design!.generalDescription != null &&
                design!.generalDescription!.isNotEmpty)
              _buildSharedInfoRow(
                'General Desc:',
                design!.generalDescription,
                icon: Icons.notes_outlined,
              ), //  مثال
            if (design!.budgetMin != null || design!.budgetMax != null) ...[
              _buildSharedSectionTitle(
                'User\'s Design Budget Range',
                context: context,
              ),
              _buildSharedInfoRow(
                'Min Estimated:',
                design!.budgetMin != null
                    ? currencyFormat.format(design!.budgetMin)
                    : 'N/A',
                icon: Icons.remove_circle_outline_outlined,
              ),
              _buildSharedInfoRow(
                'Max Estimated:',
                design!.budgetMax != null
                    ? currencyFormat.format(design!.budgetMax)
                    : 'N/A',
                icon: Icons.add_circle_outline_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 2. ويدجت اقتراح سعر (للمكتب) - ستستخدم نفس حقول الدفع العامة من ProjectModel
class ReusableOfficePaymentProposalWidget extends StatelessWidget {
  final ProjectModel project;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final bool isLoading;
  final VoidCallback onProposePayment;
  final String sectionTitle;
  final String amountLabel;
  final String buttonLabel;

  const ReusableOfficePaymentProposalWidget({
    super.key,
    required this.project,
    required this.amountController,
    required this.notesController,
    required this.isLoading,
    required this.onProposePayment,
    this.sectionTitle = 'Payment Proposal (Office)',
    this.amountLabel = 'Propose Payment Amount (JOD)',
    this.buttonLabel = 'Send Proposal to User',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    );
    const sizedBoxTiny = SizedBox(height: 8);

    //  هنا نستخدم حقول الدفع العامة للمشروع: proposedPaymentAmount, paymentNotes, paymentStatus
    //  الشروط ستعتمد على status المشروع الرئيسي
    final bool canPropose =
        (project.status ==
                'Under Office Supervision' || //  أو حالة أخرى تحددينها للإشراف
            project.status ==
                'Details Submitted - Pending Office Review' // كمثال
                ) &&
        (project.proposedPaymentAmount == null ||
            project.proposedPaymentAmount == 0) && //  لم يتم اقتراح سعر بعد
        project.paymentStatus?.toLowerCase() != 'paid'; //  ولم يتم الدفع بعد

    final bool alreadyProposed =
        project.proposedPaymentAmount != null &&
        project.proposedPaymentAmount! > 0;

    if (!canPropose && !alreadyProposed) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle(sectionTitle, context: context),
            if (alreadyProposed) ...[
              _buildSharedInfoRow(
                'Amount Proposed:',
                currencyFormat.format(project.proposedPaymentAmount!),
                icon: Icons.price_check_rounded,
              ),
              if (project.paymentNotes != null &&
                  project.paymentNotes!.isNotEmpty)
                _buildSharedInfoRow(
                  'Notes on Proposal:',
                  project.paymentNotes,
                  icon: Icons.notes_rounded,
                ),
              _buildSharedInfoRow(
                'Proposal Status:',
                project.paymentStatus ?? 'N/A',
                icon: Icons.credit_card_outlined,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  project.paymentStatus?.toLowerCase() == 'paid'
                      ? "Fee Paid by User."
                      : "Proposal Sent. Waiting for User.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color:
                        project.paymentStatus?.toLowerCase() == 'paid'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ] else if (canPropose) ...[
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: amountLabel,
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
              sizedBoxTiny,
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
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
              sizedBoxTiny,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isLoading ? 'Sending...' : buttonLabel,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  onPressed: isLoading ? null : onProposePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 3. ويدجت الدفع للمستخدم - ستستخدم نفس حقول الدفع العامة
class ReusableUserPaymentActionWidget extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onMakePayment;
  final String sectionTitle;
  final String amountLabel;
  final String payButtonLabel;

  const ReusableUserPaymentActionWidget({
    super.key,
    required this.project,
    required this.onMakePayment,
    this.sectionTitle = 'Payment Information',
    this.amountLabel = 'Amount Due (from Office):',
    this.payButtonLabel = 'Proceed to Payment',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    );

    //  الشروط تعتمد على حالة المشروع العامة وحقول الدفع العامة
    final bool paymentIsRequired =
        (project.status == 'Payment Proposal Sent' ||
            project.status == 'Awaiting User Payment' ||
            project.status == 'Awaiting User Supervision Payment') &&
        project.proposedPaymentAmount != null &&
        project.proposedPaymentAmount! > 0 &&
        project.paymentStatus?.toLowerCase() != 'paid';

    final bool isPaid =
        project.paymentStatus?.toLowerCase() == 'paid' ||
        ['In Progress', 'Completed'].contains(project.status);

    if (!paymentIsRequired && !isPaid) return const SizedBox.shrink();
    if (paymentIsRequired && isPaid) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle(sectionTitle, context: context),
            _buildSharedInfoRow(
              amountLabel,
              project.proposedPaymentAmount != null
                  ? currencyFormat.format(project.proposedPaymentAmount!)
                  : 'Not set by office yet.',
              icon: Icons.monetization_on_outlined,
            ),
            if (project.paymentNotes != null &&
                project.paymentNotes!.isNotEmpty)
              _buildSharedInfoRow(
                'Office Notes on Payment:',
                project.paymentNotes,
                icon: Icons.sticky_note_2_outlined,
              ),
            _buildSharedInfoRow(
              'Overall Payment Status:',
              project.paymentStatus ?? 'Pending',
              icon: Icons.credit_score_outlined,
            ), //  يشير إلى حالة الدفع العامة للمشروع
            const SizedBox(height: 12),
            if (paymentIsRequired)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: Text(
                    payButtonLabel,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onPressed: onMakePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            else if (isPaid)
              Center(
                child: Chip(
                  label: const Text(
                    "Payment Confirmed for Project",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green.shade600,
                  avatar: const Icon(
                    Icons.price_check_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  شاشة تفاصيل مشروع الإشراف الرئيسية
// ===========================================================================
class ProjectSupervisionDetailsScreen extends StatefulWidget {
  final int projectId;
  const ProjectSupervisionDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectSupervisionDetailsScreen> createState() =>
      _ProjectSupervisionDetailsScreenState();
}

class _ProjectSupervisionDetailsScreenState
    extends State<ProjectSupervisionDetailsScreen> {
  final ProjectService _projectService = ProjectService();
  final UserService _userService = UserService();
  ProjectModel? _project;
  // ProjectDesignModel? _projectDesign; //  سيأتي كجزء من _project
  UserModel? _currentUser;
  String? _sessionUserType;
  bool _isLoading = true;
  String? _error;

  bool _isOfficeProposingPayment = false;
  final bool _isOfficeAssigningCompany = false;
  bool _isOfficeSettingTarget = false; // من كودك السابق
  bool _isOfficeUploadingReport = false; // من كودك السابق

  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  final TextEditingController _supervisionWeeksTargetController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    _supervisionWeeksTargetController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData({bool showLoadingIndicator = true}) async {
    if (!mounted) return;
    if (showLoadingIndicator) setState(() => _isLoading = true);
    _error = null;
    try {
      final results = await Future.wait([
        _projectService.getbyofficeProjectDetails(
          widget.projectId,
        ), //  هذه يجب أن ترجع ProjectModel كاملاً
        _userService.getCurrentUserDetails(),
        Session.getUserType(),
        //  لا حاجة لجلب ProjectDesign بشكل منفصل إذا كان متضمناً في getbyofficeProjectDetails
      ]);
      if (mounted) {
        setState(() {
          _project = results[0] as ProjectModel?;
          _currentUser = results[1] as UserModel?;
          _sessionUserType = results[2] as String?;
          // _projectDesign = _project?.projectDesign; //  يمكن الوصول إليه هكذا

          if (_project != null) {
            //  تهيئة controllers الدفع (هذه ستستخدم حقول الدفع العامة للمشروع)
            if (_project!.proposedPaymentAmount != null) {
              _paymentAmountController.text = _project!.proposedPaymentAmount!
                  .toStringAsFixed(2);
            }
            _paymentNotesController.text = _project!.paymentNotes ?? '';

            if (_project!.supervisionWeeksTarget != null) {
              _supervisionWeeksTargetController.text =
                  _project!.supervisionWeeksTarget.toString();
            }
          } else {
            _error = "Supervision project data could not be loaded.";
          }
          _isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e(
        "Error loading supervision project data",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        setState(() {
          _error = "Failed to load data: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // --- دوال الأفعال ---
  Future<void> _handleProposeSupervisionPayment() async {
    //  للمكتب لاقتراح سعر الإشراف
    if (_isOfficeProposingPayment || _project == null) return;
    final amount = double.tryParse(
      _paymentAmountController.text,
    ); //  استخدام نفس controller مبدئياً
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid supervision fee."),
          ),
        );
      }
      return;
    }
    setState(() => _isOfficeProposingPayment = true);
    try {
      //  هنا، السيرفس ProjectService.proposePayment سيحدث الحقول العامة للمشروع
      //  إذا أردتِ حقولاً منفصلة لدفع الإشراف، ستحتاجين لـ API و Service function جديدة
      final updatedProject = await _projectService.proposePayment(
        widget.projectId,
        amount,
        _paymentNotesController.text, //  نفس controller الملاحظات
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Supervision payment proposal sent!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _project = updatedProject);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to send supervision proposal: ${e.toString()}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOfficeProposingPayment = false);
    }
  }

  void _handleMakeSupervisionPayment() {
    //  للمستخدم لدفع سعر الإشراف
    if (_project == null ||
        _project!.proposedPaymentAmount == null ||
        _project!.proposedPaymentAmount! <= 0) {
      return;
    }

    //  نفترض أن حالة المشروع تسمح بالدفع (مثلاً، 'Awaiting User Supervision Payment')
    //  وأننا نستخدم نفس حقول الدفع العامة
    if (_project!.status == 'Awaiting User Supervision Payment' ||
        _project!.status == 'Payment Proposal Sent') {
      //  مثال للحالات
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentScreen(
                projectId: widget.projectId,
                totalAmount: _project!.proposedPaymentAmount!,
              ),
        ),
      ).then((paymentResult) {
        if (paymentResult == true && mounted) {
          _loadInitialData(showLoadingIndicator: false);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Supervision payment is not due or already processed."),
        ),
      );
    }
  }

  Future<void> _handleAssignCompany() async {
    if (_project == null || _isOfficeAssigningCompany) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SelectCompanyForSupervisionScreen(projectId: widget.projectId),
      ),
    ).then((selectedCompanyId) {
      if (selectedCompanyId != null) {
        /* استدعاء API لربط الشركة */
      }
    });
    logger.i(
      "TODO: Navigate to screen to select company for project ${widget.projectId}",
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Assign Company (Not Implemented Yet)")),
    );
  }

  Future<void> _handleSetSupervisionTarget() async {
    /* ... نفس الكود من ملفك ... */
    if (_isOfficeSettingTarget || _project == null) return;
    final weeks = int.tryParse(_supervisionWeeksTargetController.text);
    if (weeks == null || weeks <= 0 || weeks > 52) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid number of weeks (1-52)."),
          ),
        );
      }
      return;
    }
    setState(() => _isOfficeSettingTarget = true);
    try {
      final updatedProject = await _projectService.setSupervisionTarget(
        widget.projectId,
        weeks,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Supervision target weeks set!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _project = updatedProject);
      }
    } catch (e) {
      logger.e("Error setting supervision target", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to set target: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isOfficeSettingTarget = false);
    }
  }

  Future<void> _handleUploadSupervisionReport(int weekNumber) async {
    /* ... نفس الكود من ملفك ... */
    if (_isOfficeUploadingReport || _project == null) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'zip', 'rar'],
      withData: kIsWeb,
    );
    if (result != null) {
      PlatformFile file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File is too large (max 10MB).")),
          );
        }
        return;
      }
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to read file data.")),
          );
        }
        return;
      }
      if (fileBytes != null) {
        setState(() => _isOfficeUploadingReport = true);
        try {
          final updatedProject = await _projectService.uploadSupervisionReport(
            widget.projectId,
            weekNumber,
            fileBytes,
            file.name,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Report for week $weekNumber uploaded!"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _project = updatedProject);
          }
        } catch (e) {
          logger.e("Error uploading report for week $weekNumber", error: e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to upload report: ${e.toString()}"),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isOfficeUploadingReport = false);
        }
      }
    }
  }

  final dateFormat = DateFormat('dd MMM, yyyy');

  @override
  Widget build(BuildContext context) {
    // ... (نفس build method)
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Loading Supervision ${widget.projectId}..."),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }
    if (_project == null || _currentUser == null || _sessionUserType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Data Error")),
        body: const Center(
          child: Text("Could not load critical project or user data."),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Supervision: ${_project!.name}"),
        backgroundColor: AppColors.accent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInitialData(),
          ),
        ],
      ),

      body: _buildSupervisionProjectContentView(),
    );
  }

  Widget _buildSupervisionProjectContentView() {
    if (_project == null || _currentUser == null || _sessionUserType == null) {
      return const Center(child: Text("Required data missing."));
    }

    final project = _project!;
    // ✅  الحصول على projectDesign من كائن project
    final ProjectDesignModel? design = project.projectDesign;
    final isUserOwner =
        _currentUser!.id == project.userId &&
        _sessionUserType!.toLowerCase() == 'individual';
    final isSupervisingOffice =
        _currentUser!.id == project.supervisingOfficeId &&
        _sessionUserType!.toLowerCase() == 'office';

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(showLoadingIndicator: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle(
              "Project Overview",
            ), //  استخدام الدالة المساعدة المشتركة
            _buildSharedInfoRow(
              "Project Name:",
              project.name,
              icon: Icons.bookmark_border_rounded,
            ),
            _buildSharedInfoRow(
              "Status:",
              project.status,
              icon: Icons.info_outline_rounded,
            ),
            if (project.description != null && project.description!.isNotEmpty)
              _buildSharedInfoRow(
                "General Description:",
                project.description,
                icon: Icons.description_outlined,
              ),
            const SizedBox(height: 10),

            // === 1. قسم تفاصيل التصميم (مُعاد استخدامه) ===
            ReusableDesignDetailsViewWidget(
              design: design, // ✅  تمرير design (الذي هو project.projectDesign)
              //  في شاشة الإشراف، عادة لا يتم تعديل التصميم الأصلي
              //  canUserEdit: false, //  إذا أردتِ تعطيل زر التعديل الداخلي
              //  onEditDetails: null,
            ),

            _buildStakeholderInfo(project, isUserOwner, isSupervisingOffice),

            // === 2. قسم الدفع الخاص بالإشراف ===
            if (isSupervisingOffice)
              ReusableOfficePaymentProposalWidget(
                project: project,
                amountController:
                    _paymentAmountController, //  ✅  استخدام controller الدفع العام
                notesController:
                    _paymentNotesController, //  ✅  استخدام controller الدفع العام
                isLoading:
                    _isOfficeProposingPayment, //  ✅  استخدام حالة تحميل الدفع العامة
                onProposePayment:
                    _handleProposeSupervisionPayment, //  ✅  استخدام دالة الاقتراح العامة
                sectionTitle: "Supervision Fee Proposal", //  عنوان مخصص للإشراف
                amountLabel: "Propose Supervision Fee (JOD)",
                buttonLabel: "Send Supervision Fee Proposal",
              ),

            if (isUserOwner)
              ReusableUserPaymentActionWidget(
                project: project,
                onMakePayment:
                    _handleMakeSupervisionPayment, //  ✅  استخدام دالة الدفع العامة
                sectionTitle: "Supervision Fee Payment", //  عنوان مخصص
                amountLabel: "Supervision Fee Due:",
                payButtonLabel: "Pay Supervision Fee",
              ),

            // === 3. كبسة للمكتب لتعيين شركة (إذا لم يتم تعيينها) ===
            if (isSupervisingOffice &&
                project.companyId == null &&
                (project.status == 'Under Office Supervision' ||
                    project.status == 'In Progress' /* أو حالات أخرى */ )) ...[
              const Divider(height: 24, thickness: 0.5),
              _buildSharedSectionTitle("Construction Company Assignment"),
              Center(
                child: Column(
                  children: [
                    Text(
                      "No construction company assigned yet.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon:
                          _isOfficeAssigningCompany
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.add_business_outlined,
                                size: 18,
                              ),
                      label: Text(
                        _isOfficeAssigningCompany
                            ? "Processing..."
                            : "Assign Construction Company",
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed:
                          _isOfficeAssigningCompany
                              ? null
                              : _handleAssignCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (project.company != null) ...[
              _buildSharedSectionTitle("Assigned Construction Company"),
              //  عرض معلومات الشركة
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      project.company!.profileImage != null &&
                              project.company!.profileImage!.isNotEmpty
                          ? NetworkImage(
                            project.company!.profileImage!.startsWith('http')
                                ? project.company!.profileImage!
                                : '${Constants.baseUrl}/${project.company!.profileImage}',
                          )
                          : null,
                  child:
                      (project.company!.profileImage == null ||
                              project.company!.profileImage!.isEmpty)
                          ? Icon(Icons.business_center)
                          : null,
                ),
                title: Text(project.company!.name),
                subtitle: Text(project.company!.companyType ?? "N/A"),
                // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CompanyReadOnlyProfileScreen(companyId: project.company!.id))),
              ),
            ],

            //  أقسام الإشراف الأخرى (التي كانت لديكِ)
            if (isSupervisingOffice)
              _buildOfficeSupervisionReportSection(project),
            if (isUserOwner) _buildUserSupervisionProgressViewHabela(project),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeholderInfo(
    ProjectModel project,
    bool isUserOwner,
    bool isSupervisingOffice,
  ) {
    /* ... نفس الكود من ملفك ... */
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16, top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.supervisingOffice != null) ...[
              //  ✅  استخدام supervisingOffice
              _buildSharedSectionTitle('Supervising Office'),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      project.supervisingOffice!.profileImage != null &&
                              project
                                  .supervisingOffice!
                                  .profileImage!
                                  .isNotEmpty
                          ? NetworkImage(
                            project.supervisingOffice!.profileImage!.startsWith(
                                  'http',
                                )
                                ? project.supervisingOffice!.profileImage!
                                : '${Constants.baseUrl}/${project.supervisingOffice!.profileImage}',
                          )
                          : null,
                  backgroundColor: Colors.grey[200],
                  child:
                      project.supervisingOffice!.profileImage == null ||
                              project.supervisingOffice!.profileImage!.isEmpty
                          ? const Icon(
                            Icons.business_center_rounded,
                            color: AppColors.primary,
                          )
                          : null,
                ),
                title: Text(
                  project.supervisingOffice!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  project.supervisingOffice!.location ??
                      'Location not specified',
                ),
                onTap: () {
                  //  تحديد إذا كان المستخدم الحالي هو نفس المكتب المشرف
                  bool isCurrentOfficeTheSupervisor =
                      _sessionUserType == 'office' &&
                      _currentUser?.id == project.supervisingOffice!.id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OfficeProfileScreen(
                            officeId: project.supervisingOffice!.id,
                            isOwner:
                                isCurrentOfficeTheSupervisor, //  isOwner بناءً على المستخدم الحالي
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            if (project.office != null &&
                project.officeId != project.supervisingOfficeId) ...[
              // ✅ عرض المكتب المصمم إذا كان مختلفاً
              _buildSharedSectionTitle('Design Office'),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      project.office!.profileImage != null &&
                              project.office!.profileImage!.isNotEmpty
                          ? NetworkImage(
                            project.office!.profileImage!.startsWith('http')
                                ? project.office!.profileImage!
                                : '${Constants.baseUrl}/${project.office!.profileImage}',
                          )
                          : null,
                  backgroundColor: Colors.grey[200],
                  child:
                      project.office!.profileImage == null ||
                              project.office!.profileImage!.isEmpty
                          ? const Icon(
                            Icons.design_services_rounded,
                            color: AppColors.primary,
                          )
                          : null,
                ),
                title: Text(
                  project.office!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  project.office!.location ?? 'Location not specified',
                ),
                onTap: () {
                  bool isCurrentOfficeTheDesigner =
                      _sessionUserType == 'office' &&
                      _currentUser?.id == project.office!.id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => OfficeProfileScreen(
                            officeId: project.office!.id,
                            isOwner: isCurrentOfficeTheDesigner,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            if (project.user != null && !isUserOwner) ...[
              _buildSharedSectionTitle('Project Owner'),
              ListTile(/* ... نفس الكود ... */),
              const SizedBox(height: 8),
            ],
            if (project.company != null) ...[
              _buildSharedSectionTitle('Assigned Construction Company'),
              ListTile(/* ... نفس الكود ... */),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeSupervisionReportSection(ProjectModel project) {
    /* ... نفس الكود من ملفك ... */
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16, top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle('Supervision Weekly Reports (Office)'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _supervisionWeeksTargetController,
                    decoration: InputDecoration(
                      labelText: 'Total Supervision Weeks',
                      hintText: 'e.g., 10',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly:
                        _isOfficeSettingTarget ||
                        (project.supervisionWeeksTarget ?? 0) > 0,
                    validator:
                        (val) =>
                            (val == null ||
                                    val.isEmpty ||
                                    int.tryParse(val) == null ||
                                    int.parse(val) <= 0 ||
                                    int.parse(val) > 52)
                                ? 'Weeks (1-52)'
                                : null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      (_isOfficeSettingTarget ||
                              (project.supervisionWeeksTarget ?? 0) > 0)
                          ? null
                          : _handleSetSupervisionTarget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child:
                      _isOfficeSettingTarget
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Set", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            if ((project.supervisionWeeksTarget ?? 0) > 0) ...[
              const Divider(height: 24),
              Text(
                "Upload Weekly Reports:",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: project.supervisionWeeksTarget!,
                itemBuilder: (context, index) {
                  int weekNum = index + 1;
                  bool reportConsideredSubmitted =
                      (project.supervisionWeeksCompleted ?? 0) >= weekNum;
                  bool canUploadNow =
                      (project.supervisionWeeksCompleted ?? 0) ==
                          (weekNum - 1) ||
                      reportConsideredSubmitted;

                  String? reportPathForThisWeek =
                      (reportConsideredSubmitted &&
                              project.agreementFile != null &&
                              project.agreementFile!.isNotEmpty)
                          ? project.agreementFile
                          : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              reportConsideredSubmitted
                                  ? Icons.check_box_rounded
                                  : canUploadNow
                                  ? Icons.edit_document
                                  : Icons.hourglass_empty_rounded,
                              color:
                                  reportConsideredSubmitted
                                      ? Colors.green
                                      : canUploadNow
                                      ? AppColors.accent
                                      : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Week $weekNum Report",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (reportPathForThisWeek != null)
                          TextButton.icon(
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: AppColors.accent.withAlpha(
                                (0.8 * 255).round(),
                              ),
                            ),
                            label: Text(
                              "View Last",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accent.withAlpha(
                                  (0.8 * 255).round(),
                                ),
                              ),
                            ),
                            onPressed: () async {
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
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 20),
                            ),
                          )
                        else if (canUploadNow)
                          ElevatedButton(
                            onPressed:
                                _isOfficeUploadingReport
                                    ? null
                                    : () =>
                                        _handleUploadSupervisionReport(weekNum),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  reportConsideredSubmitted
                                      ? Colors.orange.shade700
                                      : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            child:
                                _isOfficeUploadingReport &&
                                        (project.supervisionWeeksCompleted ??
                                                0) ==
                                            (weekNum - 1)
                                    ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      reportConsideredSubmitted
                                          ? "Re-upload"
                                          : "Upload",
                                    ),
                          )
                        else
                          Text(
                            "(Upcoming)",
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Set supervision target weeks to enable report uploads.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSupervisionProgressViewHabela(ProjectModel project) {
    /* ... نفس الكود من ملفك ... */
    if (project.supervisionWeeksTarget == null ||
        project.supervisionWeeksTarget! <= 0) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16, top: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSharedSectionTitle('Supervision Progress'),
              Center(
                child: Text(
                  "Supervision target not set by office yet.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    int target = project.supervisionWeeksTarget!;
    int completed = project.supervisionWeeksCompleted ?? 0;
    if (completed > target) completed = target;
    double progress = (target > 0) ? (completed / target) : 0.0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16, top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSharedSectionTitle('Supervision Progress'),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primary.withAlpha(
                        (0.3 * 255).round(),
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}% ($completed/$target W)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Weekly Reports (from Office):",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (completed == 0 &&
                (project.agreementFile == null ||
                    project.agreementFile!.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "No reports submitted yet.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    completed > 0
                        ? completed
                        : (project.agreementFile != null &&
                                project.agreementFile!.isNotEmpty
                            ? 1
                            : 0),
                itemBuilder: (context, index) {
                  int weekNum = index + 1;
                  //  TODO: هذا الجزء يحتاج لتعديل ليجلب مسار الملف الصحيح لكل أسبوع
                  String? reportPathForThisWeek =
                      (project.agreementFile != null &&
                              project.agreementFile!.isNotEmpty &&
                              weekNum <= completed)
                          ? project.agreementFile
                          : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Report for Week $weekNum ${weekNum > completed ? '(Latest)' : ''}",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (reportPathForThisWeek != null)
                          TextButton.icon(
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: AppColors.accent.withAlpha(
                                (0.8 * 255).round(),
                              ),
                            ),
                            label: Text(
                              "View",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accent.withAlpha(
                                  (0.8 * 255).round(),
                                ),
                              ),
                            ),
                            onPressed: () async {
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
                                );
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
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 20),
                            ),
                          )
                        else
                          Text(
                            "(File N/A)",
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.red.shade400,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
