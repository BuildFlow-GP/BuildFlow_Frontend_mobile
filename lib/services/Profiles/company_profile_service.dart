import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session.dart';
import 'package:logger/logger.dart';
import '../../utils/constants.dart';

class CompanyService {
  static const String baseUrl = '${Constants.baseUrl}/companies';

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final Logger logger = Logger();

    final token = await Session.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      logger.e('Failed to load profile: ${response.body}');
      return null;
    }
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await Session.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }
}
