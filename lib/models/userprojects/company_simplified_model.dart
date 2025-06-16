// models/simplified_company_model.dart
class SimplifiedCompanyModel {
  final int id;
  final String name;
  final String? profileImage;

  SimplifiedCompanyModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory SimplifiedCompanyModel.fromJson(Map<String, dynamic> json) {
    return SimplifiedCompanyModel(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}
