class OfficeModel {
  final int id;
  String name; // أصبح nullable
  String? email; // أصبح nullable
  String? phone; // أصبح nullable
  String? location; // أصبح nullable
  int? capacity;
  double? rating;
  bool? isAvailable; // أصبح nullable
  int? points; // أصبح nullable
  String? bankAccount;
  int? staffCount;
  int? activeProjectsCount; // أصبح nullable
  String? branches;
  String? profileImage;
  String? createdAt; // أصبح nullable

  OfficeModel({
    required this.id,
    required this.name, // لم يعد required
    this.email, // لم يعد required
    this.phone, // لم يعد required
    this.location, // لم يعد required
    this.capacity,
    this.rating,
    this.isAvailable, // لم يعد required
    this.points, // لم يعد required
    this.bankAccount,
    this.staffCount,
    this.activeProjectsCount, // لم يعد required
    this.branches,
    this.profileImage,
    this.createdAt, // لم يعد required
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      id: json['id'] as int,
      name: json['name'] as String, // سيأخذ null إذا كان name غير موجود أو null
      email: json['email'] as String?,
      phone:
          json['phone']
              as String?, // كان لديك phone ?? '' وهو جيد، لكن هنا نجعله يقبل null مباشرة
      location: json['location'] as String?,
      capacity: json['capacity'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable:
          json['is_available'] as bool? ??
          true, // قيمة افتراضية إذا كان null أو مفقود
      points: json['points'] as int? ?? 0, // قيمة افتراضية
      bankAccount: json['bank_account'] as String?,
      staffCount: json['staff_count'] as int?,
      activeProjectsCount:
          json['active_projects_count'] as int? ?? 0, // قيمة افتراضية
      branches: json['branches'] as String?,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    // أعدت بناء toJson ليكون أكثر أمانًا مع القيم الاختيارية
    // ولإرسال الحقول التي عادة ما يتم تعديلها
    // (قد تحتاجين لتعديل هذا بناءً على ما يتوقعه الـ API عند الإنشاء/التحديث)
    "name": name,
    "email": email,
    "phone": phone,
    "location": location,
    "capacity": capacity,
    // "rating": rating, // عادة لا يرسل
    "is_available": isAvailable,
    // "points": points, // عادة لا يرسل
    "bank_account": bankAccount,
    "staff_count": staffCount,
    // "active_projects_count": activeProjectsCount, // عادة لا يرسل
    "branches": branches,
    "profile_image": profileImage,
    // "id": id, // لا يرسل عند الإنشاء، قد يرسل عند التحديث في body أو كـ param
    // "created_at": createdAt, // لا يرسل
  };
}
