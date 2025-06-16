// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/Constants.dart';
import '../session.dart';
import 'package:logger/logger.dart';

class UserService {
  static const String baseUrl = "${Constants.baseUrl}/users";

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final Logger logger = Logger();

    final token = await Session.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      logger.e("Error fetching user profile: ${res.body}");
      return null;
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    final token = await Session.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  // يمكنكِ إضافة دالة لرفع صورة بروفايل المستخدم هنا لاحقاً
  // Future<String?> uploadUserProfileImage(Uint8List imageBytes, String fileName) async { ... }
}
