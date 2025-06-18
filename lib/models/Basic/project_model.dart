// models/project_model.dart (أو المسار الصحيح لديكِ models/Basic/project_model.dart)
import '../create/project_design_model.dart';
import 'office_model.dart'; // تأكدي من المسارات الصحيحة
import 'company_model.dart';
import 'user_model.dart';

class ProjectModel {
  final int id;
  String name; // اسم المشروع، لا يجب أن يكون null
  String? description; // الوصف، سنجعله نص فارغ إذا كان null
  String? status; // الحالة، سنجعلها قيمة افتراضية إذا كانت null
  double? budget;
  DateTime? startDate; //  تم تحويله لـ DateTime
  DateTime? endDate; //  تم تحويله لـ DateTime
  String? location; //  سنجعله نص فارغ إذا كان null

  // حقول معلومات الأرض
  double? landArea;
  String? plotNumber; //  سنجعله نص فارغ إذا كان null
  String? basinNumber; //  سنجعله نص فارغ إذا كان null
  String? landLocation; //  سنجعله نص فارغ إذا كان null

  // حقول المستندات (تبقى String? لأنها قد لا تكون موجودة دائماً)
  String? licenseFile;
  String? agreementFile;
  String? document2D;
  String? document3D;
  String? planner5dUrl;
  String? architecturalfile;
  String? structuralfile; //  أو document_2
  String? electricalfile; //  أو document_3
  String? mechanicalfile; //  أو document_4

  String? rejectionReason; //  إذا أضفتيه في الـ backend model
  final double? proposedPaymentAmount;
  final double? supervisionPaymentAmount;
  final String? supervisionPaymentStatus;
  final int? supervisionWeeksTarget; //  العدد الإجمالي لأسابيع الإشراف
  final int? supervisionWeeksCompleted; //  عدد الأسابيع التي تم "رفع" تقرير لها
  final String? paymentNotes;
  final String? paymentStatus;
  final int? progressStage; //  (0-5 مثلاً)
  final DateTime createdAt; //  تم تحويله لـ DateTime

  // IDs للربط (مهمة جداً)
  final int? userId;
  final int? officeId;
  final int? supervisingOfficeId;
  final int? companyId;
  ProjectDesignModel? projectDesign; // ✅✅✅ أضيفي هذا الحقل ✅✅✅

  // final int? companyId; // إذا كنتِ ستضيفينه

  // الكائنات المتداخلة (إذا أرجعها الـ API)
  OfficeModel? office;
  CompanyModel? company;
  UserModel? user;
  OfficeModel? supervisingOffice;

  ProjectModel({
    required this.id,
    required this.name,
    this.description = '', // قيمة افتراضية
    this.status = 'Unknown', // قيمة افتراضية
    this.budget,
    this.startDate,
    this.endDate,
    this.location = '', // قيمة افتراضية
    this.licenseFile,
    this.agreementFile,
    this.document2D,
    this.document3D,
    this.architecturalfile,
    this.structuralfile, //  أو document_2
    this.electricalfile, //  أو document_3
    this.mechanicalfile, //  أو document_4
    this.landArea,
    this.plotNumber = '', // قيمة افتراضية
    this.basinNumber = '', // قيمة افتراضية
    this.landLocation = '', // قيمة افتراضية
    this.rejectionReason,
    this.proposedPaymentAmount,
    this.paymentNotes,
    this.paymentStatus,
    this.progressStage,
    required this.createdAt,
    this.planner5dUrl,
    this.userId,
    this.officeId,
    this.companyId,
    this.office,
    this.company,
    this.user,
    this.projectDesign,
    this.supervisingOfficeId,
    this.supervisionPaymentAmount,
    this.supervisionPaymentStatus,
    this.supervisionWeeksTarget,
    this.supervisionWeeksCompleted,
    this.supervisingOffice,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      return DateTime.tryParse(dateString);
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProjectModel(
      id: json['id'] as int,
      name:
          json['name'] as String? ??
          'Unnamed Project', // قيمة افتراضية قوية للاسم
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Unknown',
      budget: parseDouble(json['budget']),
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),
      location: json['location'] as String? ?? '',
      proposedPaymentAmount: parseDouble(json['proposed_payment_amount']),
      paymentNotes: json['payment_notes'] as String?,
      paymentStatus: json['payment_status'] as String?,
      progressStage: json['progress_stage'] as int?,

      licenseFile: json['license_file'] as String?,
      agreementFile: json['agreement_file'] as String?,
      document2D: json['document_2d'] as String?,
      document3D: json['document_3d'] as String?,
      architecturalfile: json['architectural_file'] as String?,
      structuralfile: json['structural_file'] as String?,
      electricalfile: json['electrical_file'] as String?,
      mechanicalfile: json['mechanical_file'] as String?,

      landArea: parseDouble(json['land_area']),
      plotNumber: json['plot_number'] as String? ?? '',
      basinNumber: json['basin_number'] as String? ?? '',
      landLocation: json['land_location'] as String? ?? '',
      planner5dUrl: json['planner5dUrl'] as String?,
      rejectionReason: json['rejection_reason'] as String?,

      createdAt:
          parseDate(json['created_at'] as String?) ??
          DateTime.now(), // قيمة افتراضية قوية

      userId: json['user_id'] as int?, //  قراءة الـ ID
      officeId: json['office_id'] as int?, //  قراءة الـ ID

      supervisingOfficeId:
          json['supervising_office_id'] as int?, //  قراءة الـ ID
      companyId: json['assigned_company_id'] as int?, //  قراءة الـ ID
      supervisionPaymentAmount: parseDouble(json['supervision_payment_amount']),
      supervisionPaymentStatus: json['supervision_payment_status'] as String?,
      supervisionWeeksTarget: json['supervision_weeks_target'] as int?,
      supervisionWeeksCompleted: json['supervision_weeks_completed'] as int?,
      projectDesign:
          json['projectDesign'] != null
              ? ProjectDesignModel.fromJson(
                json['projectDesign'] as Map<String, dynamic>,
              )
              : null, // ✅
      supervisingOffice:
          json['supervising_office'] != null
              ? OfficeModel.fromJson(
                json['supervising_office'] as Map<String, dynamic>,
              )
              : null, // ✅
      office:
          json['office'] != null
              ? OfficeModel.fromJson(json['office'] as Map<String, dynamic>)
              : null,
      user:
          json['user'] != null
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      company:
          json['company'] != null
              ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (description!.isNotEmpty) data['description'] = description;
    // if (status.isNotEmpty && status != 'Unknown') data['status'] = status;
    if (budget != null) data['budget'] = budget;
    if (startDate != null) data['start_date'] = startDate!.toIso8601String();
    if (endDate != null) data['end_date'] = endDate!.toIso8601String();
    if (location!.isNotEmpty) data['location'] = location;
    if (planner5dUrl != null) data['planner5dUrl'] = planner5dUrl;
    // if (licenseFile != null) data['license_file'] = licenseFile;
    // if (agreementFile != null) data['agreement_file'] = agreementFile;
    // if (document2D != null) data['document_2d'] = document2D;
    // if (document3D != null) data['document_3d'] = document3D;

    if (landArea != null) data['land_area'] = landArea;
    if (plotNumber!.isNotEmpty) data['plot_number'] = plotNumber;
    if (basinNumber!.isNotEmpty) data['basin_number'] = basinNumber;
    if (landLocation!.isNotEmpty) data['land_location'] = landLocation;
    if (proposedPaymentAmount != null) {
      data['proposed_payment_amount'] = proposedPaymentAmount;
    }
    if (paymentNotes != null) data['payment_notes'] = paymentNotes;
    if (paymentStatus != null) data['payment_status'] = paymentStatus;
    if (progressStage != null) data['progress_stage'] = progressStage;

    return data;
  }
}
