class UserModel {
  final int id;
  String name;
  String email;
  String phone;
  String? idNumber;
  String? bankAccount;
  String? location;
  String? profileImage;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.idNumber,
    this.bankAccount,
    this.location,
    this.profileImage,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      idNumber: json['id_number'],
      bankAccount: json['bank_account'],
      location: json['location'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
    "id_number": idNumber,
    "bank_account": bankAccount,
    "location": location,
    "profile_image": profileImage,
  };
}
