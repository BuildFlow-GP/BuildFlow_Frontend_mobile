// models/project_model.dart
import '../Basic/user_model.dart'; // لاستخدام UserModel الكامل
import '../Basic/office_model.dart'; // لاستخدام OfficeModel الكامل
import '../Basic/company_model.dart'; // لاستخدام CompanyModel الكامل

class ProjectreadonlyModel {
  final int id;
  final String name; // الحقول المطلوبة لن تكون null
  final String? description;
  final String status; // افترض أن الحالة مطلوبة
  final double? budget;
  final DateTime? startDate; // استخدام DateTime مباشرة
  final DateTime? endDate;
  final String? location;
  final String? licenseFile;
  final String? agreementFile;
  final String? document2D;
  final String? document3D;
  final double? landArea;
  final String? plotNumber;
  final String? basinNumber;
  final String? landLocation;
  final DateTime createdAt; // مطلوبة
  final int? userId; //  ID المستخدم مالك المشروع (إذا أردتِ إظهاره)

  // استخدام الموديلات الكاملة هنا لأننا في صفحة التفاصيل قد نحتاج لكل البيانات
  final UserModel? user;
  final OfficeModel? office;
  final CompanyModel? company;

  ProjectreadonlyModel({
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
    this.userId, // userId هو الـ foreign key من جدول المشاريع
    this.user, // الكائن المتداخل
    this.office,
    this.company,
  });

  factory ProjectreadonlyModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لتحويل النصوص إلى DateTime بأمان
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      return DateTime.tryParse(dateString);
    }

    // دالة مساعدة لتحويل النصوص إلى double بأمان
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProjectreadonlyModel(
      id: json['id'] as int,
      name:
          json['name'] as String? ??
          'Unnamed Project', // قيمة افتراضية إذا كان null
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Unknown', // قيمة افتراضية
      budget: parseDouble(json['budget']),
      startDate: parseDate(json['start_date'] as String?),
      endDate: parseDate(json['end_date'] as String?),
      location: json['location'] as String?,
      licenseFile: json['license_file'] as String?,
      agreementFile: json['agreement_file'] as String?,
      document2D: json['document_2d'] as String?,
      document3D: json['document_3d'] as String?,
      landArea: parseDouble(json['land_area']),
      plotNumber: json['plot_number'] as String?,
      basinNumber: json['basin_number'] as String?,
      landLocation: json['land_location'] as String?,
      createdAt:
          parseDate(json['created_at'] as String?) ??
          DateTime.now(), // قيمة افتراضية
      userId: json['user_id'] as int?, // من جدول المشاريع نفسه
      user:
          json['user'] != null
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      office:
          json['office'] != null
              ? OfficeModel.fromJson(json['office'] as Map<String, dynamic>)
              : null,
      company:
          json['company'] != null
              ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
              : null,
    );
  }

  // toJson() - لإرسال البيانات للـ backend (قد تحتاجين لتعديله)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['status'] = status;
    data['budget'] = budget;
    data['start_date'] = startDate?.toIso8601String();
    data['end_date'] = endDate?.toIso8601String();
    data['location'] = location;
    data['license_file'] = licenseFile;
    data['agreement_file'] = agreementFile;
    data['document_2d'] = document2D;
    data['document_3d'] = document3D;
    data['land_area'] = landArea;
    data['plot_number'] = plotNumber;
    data['basin_number'] = basinNumber;
    data['land_location'] = landLocation;
    // عادةً ما نرسل الـ IDs للكائنات المرتبطة بدلاً من الكائنات الكاملة
    if (user != null) {
      data['user_id'] = user!.id; // أو user_id مباشرة إذا كان متوفراً
    }
    if (office != null) data['office_id'] = office!.id;
    if (company != null) data['company_id'] = company!.id;
    return data;
  }
}
