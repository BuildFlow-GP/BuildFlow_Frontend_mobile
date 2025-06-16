class SimplifiedOfficeModel {
  final int id;
  final String name;
  final String? profileImage;

  SimplifiedOfficeModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory SimplifiedOfficeModel.fromJson(Map<String, dynamic> json) {
    return SimplifiedOfficeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImage: json['profile_image'] as String?,
    );
  }
}
