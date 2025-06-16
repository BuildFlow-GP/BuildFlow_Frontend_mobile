// models/project_model.dart
import 'office_simplified_model.dart';
import 'company_simplified_model.dart';

class ProjectsimplifiedModel {
  final int id;
  final String name;
  final String? description; // وصف كامل، قد لا يعرض كاملاً في الكرت
  final String status;
  final double? budget;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location; // موقع المشروع العام
  // الحقول التالية قد لا تعرض في الكرت ولكنها جزء من الموديل الكامل
  final String? licenseFile;
  final String? agreementFile;
  final String? document2D;
  final String? document3D;
  final double? landArea;
  final String? plotNumber;
  final String? basinNumber;
  final String? landLocation; // تفاصيل موقع الأرض
  final DateTime createdAt;
  final int? userId;
  final int? officeId;
  final int? companyId;
  final SimplifiedOfficeModel? office; // مكتب مبسط
  final SimplifiedCompanyModel? company; // شركة مبسطة

  ProjectsimplifiedModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.budget,
    this.startDate,
    this.endDate,
    this.location,
    this.licenseFile,
    this.agreementFile,
    this.document2D,
    this.document3D,
    this.landArea,
    this.plotNumber,
    this.basinNumber,
    this.landLocation,
    required this.createdAt,
    this.userId,
    this.officeId,
    this.companyId,
    this.office,
    this.company,
  });

  factory ProjectsimplifiedModel.fromJson(Map<String, dynamic> json) {
    return ProjectsimplifiedModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      budget:
          json['budget'] != null
              ? double.tryParse(json['budget'].toString()) // تحويل آمن
              : null,
      startDate:
          json['start_date'] != null
              ? DateTime.tryParse(json['start_date'] as String)
              : null,
      endDate:
          json['end_date'] != null
              ? DateTime.tryParse(json['end_date'] as String)
              : null,
      location: json['location'] as String?,
      licenseFile: json['license_file'] as String?,
      agreementFile: json['agreement_file'] as String?,
      document2D: json['document_2d'] as String?,
      document3D: json['document_3d'] as String?,
      landArea:
          json['land_area'] != null
              ? double.tryParse(json['land_area'].toString()) // تحويل آمن
              : null,
      plotNumber: json['plot_number'] as String?,
      basinNumber: json['basin_number'] as String?,
      landLocation: json['land_location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as int?,
      officeId: json['office_id'] as int?,
      companyId: json['company_id'] as int?,
      office:
          json['office'] != null
              ? SimplifiedOfficeModel.fromJson(
                json['office'] as Map<String, dynamic>,
              )
              : null,
      company:
          json['company'] != null
              ? SimplifiedCompanyModel.fromJson(
                json['company'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  // toJson() يمكن إضافته إذا احتجتِ لإرسال بيانات المشروع للـ backend
}
