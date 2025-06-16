class CompanyModel {
  final int id;
  String name; // أصبح nullable
  String? email;
  String? phone;
  String? description;
  double? rating;
  String? companyType;
  String? location;
  String? bankAccount;
  int? staffCount;
  String? profileImage;
  String? createdAt; // أصبح nullable

  CompanyModel({
    required this.id,
    required this.name, // لم يعد required
    this.email,
    this.phone,
    this.description,
    this.rating,
    this.companyType,
    this.location,
    this.bankAccount,
    this.staffCount,
    this.profileImage,
    this.createdAt, // لم يعد required
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as int,
      name: json['name'] as String, // سيأخذ null إذا كان name غير موجود أو null
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      companyType: json['company_type'] as String?,
      location: json['location'] as String?,
      bankAccount: json['bank_account'] as String?,
      staffCount: json['staff_count'] as int?,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
    "description": description,
    // "rating": rating, // عادة لا يرسل
    "company_type": companyType,
    "location": location,
    "bank_account": bankAccount,
    "staff_count": staffCount,
    "profile_image": profileImage,
  };
}
