import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../utils/constants.dart';

class OfficeService {
  static const String baseUrl = Constants.baseUrl;

  static Future<Map<String, dynamic>> getOffice(int id, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/offices/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load office');
    }
  }

  static Future<void> updateOffice(
    int id,
    Map<String, dynamic> data,
    String? token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offices/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update office');
    }
  }

  static Future<void> uploadOfficeImage(
    int id,
    File image,
    String? token,
  ) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/offices/$id'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('profile_image', image.path),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image');
    }
  }
}
