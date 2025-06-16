import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../session.dart';
import '../../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح

class AuthService {
  final String baseUrl = '${Constants.baseUrl}/auth';
  final Logger logger = Logger();

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      logger.i('Response: ${response.body}');

      if (response.statusCode == 200) {
        final token = data['token'];
        final userType = data['type'];
        final user = data['user'];

        // خزن التوكن و بيانات السيشن باستخدام Session class
        if (token != null) await Session.setToken(token);
        if (userType != null && user != null && user['id'] != null) {
          await Session.setSession(type: userType, id: user['id']);
        }

        return data;
      } else {
        logger.e('Login failed: ${response.body}');
        throw Exception('Login failed: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      logger.e('Error during login request: $e');
      rethrow;
    }
  }

  // جلب التوكن باستخدام Session
  Future<String?> getToken() async {
    return await Session.getToken();
  }

  // مسح السيشن بالكامل عند تسجيل الخروج
  Future<void> logout() async {
    await Session.clear();
  }
}
