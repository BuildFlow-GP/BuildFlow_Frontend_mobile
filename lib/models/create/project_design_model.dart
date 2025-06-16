// models/project_design_model.dart (أو اسم مشابه)
class ProjectDesignModel {
  final int? id; //  قد يكون null إذا لم يتم إنشاؤه بعد في DB
  final int projectId; //  مهم للربط
  final int? floorCount;
  final int? bedrooms;
  final int? bathrooms;
  final int? kitchens;
  final int? balconies;
  final List<String>? specialRooms; //  قائمة من النصوص
  final Map<String, dynamic>? directionalRooms; //  JSON سيتم تحويله لـ Map
  final String? kitchenType;
  final bool? masterHasBathroom;
  final String? generalDescription;
  final String? interiorDesign;
  final String? roomDistribution;
  final double? budgetMin; //  تمت الإضافة
  final double? budgetMax; //  تمت الإضافة
  final DateTime? createdAt; //  إذا كان الـ backend يرجعها
  final DateTime? updatedAt; //  إذا كان الـ backend يرجعها

  ProjectDesignModel({
    this.id,
    required this.projectId,
    this.floorCount,
    this.bedrooms,
    this.bathrooms,
    this.kitchens,
    this.balconies,
    this.specialRooms,
    this.directionalRooms,
    this.kitchenType,
    this.masterHasBathroom,
    this.generalDescription,
    this.interiorDesign,
    this.roomDistribution,
    this.budgetMin,
    this.budgetMax,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectDesignModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لتحويل json['special_rooms'] (التي قد تكون List<dynamic>) إلى List<String>
    List<String>? parseSpecialRooms(dynamic list) {
      if (list == null || list is! List) return null;
      return List<String>.from(list.map((item) => item.toString()));
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      return DateTime.tryParse(dateString);
    }

    return ProjectDesignModel(
      id: json['id'] as int?,
      projectId:
          json['project_id'] as int, //  يفترض أن الـ backend يرجع project_id
      floorCount: json['floor_count'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      kitchens: json['kitchens'] as int?,
      balconies: json['balconies'] as int?,
      specialRooms: parseSpecialRooms(json['special_rooms']),
      directionalRooms: json['directional_rooms'] as Map<String, dynamic>?,
      kitchenType: json['kitchen_type'] as String?,
      masterHasBathroom: json['master_has_bathroom'] as bool?,
      generalDescription: json['general_description'] as String?,
      interiorDesign: json['interior_design'] as String?,
      roomDistribution: json['room_distribution'] as String?,
      budgetMin: parseDouble(json['budget_min']),
      budgetMax: parseDouble(json['budget_max']),
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // لا نرسل id أو project_id عادةً في الـ body لـ POST/PUT إذا كانا في الـ URL
    // ولكن upsert قد يحتاجهما أو يعتمد على العلاقة
    // data['project_id'] = projectId; //  تأكدي إذا كان الـ API يتوقعه في الـ body

    if (floorCount != null) data['floor_count'] = floorCount;
    if (bedrooms != null) data['bedrooms'] = bedrooms;
    if (bathrooms != null) data['bathrooms'] = bathrooms;
    if (kitchens != null) data['kitchens'] = kitchens;
    if (balconies != null) data['balconies'] = balconies;
    if (specialRooms != null && specialRooms!.isNotEmpty) {
      data['special_rooms'] = specialRooms;
    }
    if (directionalRooms != null && directionalRooms!.isNotEmpty) {
      data['directional_rooms'] = directionalRooms;
    }
    if (kitchenType != null && kitchenType!.isNotEmpty) {
      data['kitchen_type'] = kitchenType;
    }
    if (masterHasBathroom != null) {
      data['master_has_bathroom'] = masterHasBathroom;
    }
    if (generalDescription != null && generalDescription!.isNotEmpty) {
      data['general_description'] = generalDescription;
    }
    if (interiorDesign != null && interiorDesign!.isNotEmpty) {
      data['interior_design'] = interiorDesign;
    }
    if (roomDistribution != null && roomDistribution!.isNotEmpty) {
      data['room_distribution'] = roomDistribution;
    }
    if (budgetMin != null) data['budget_min'] = budgetMin;
    if (budgetMax != null) data['budget_max'] = budgetMax;

    return data;
  }
}
