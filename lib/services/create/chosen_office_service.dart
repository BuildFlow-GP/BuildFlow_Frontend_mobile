import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح

final logger = Logger();

class Office {
  final int id;
  final String name;
  final String location;
  final String imageUrl;
  final double rating;

  Office({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.rating,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      imageUrl: json['profile_image'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    );
  }
}

class OfficeService {
  static const String baseUrl = '${Constants.baseUrl}/offices';

  static Future<List<Office>> fetchSuggestedOffices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/suggestions'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> offices = data['offices'];
        return offices.map((e) => Office.fromJson(e)).toList();
      } else {
        logger.e('Failed to load offices: ${response.body}');
        return [];
      }
    } catch (e) {
      logger.e('Exception during office fetch: $e');
      return [];
    }
  }
}
