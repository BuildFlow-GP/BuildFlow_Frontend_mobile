import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/constants.dart';

class ReviewService {
  static const String baseUrl = Constants.baseUrl;

  static Future<List<dynamic>> getOfficeReviews(
    int officeId,
    String? token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/office/$officeId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }
}
