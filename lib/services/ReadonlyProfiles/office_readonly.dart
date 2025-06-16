// services/office_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/office_model.dart';
import '../../models/Basic/project_model.dart';
import '../../models/Basic/review_model.dart'; // استخدام ReviewModel الخاص بكِ
import '../session.dart';
import '../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح
import 'package:logger/logger.dart';

class OfficeProfileService {
  static const String _baseUrl = Constants.baseUrl;
  final Logger logger = Logger();

  Future<OfficeModel> getOfficeDetails(int officeId) async {
    final response = await http.get(Uri.parse('$_baseUrl/offices/$officeId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OfficeModel.fromJson(data);
    } else {
      logger.e(
        'Failed to load office details: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load office details (Status: ${response.statusCode})',
      );
    }
  }

  Future<List<ProjectModel>> getOfficeProjects(int officeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$officeId/officeprojects'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map(
            (projectJson) =>
                ProjectModel.fromJson(projectJson as Map<String, dynamic>),
          )
          .toList();
    } else {
      logger.e(
        'Failed to load office projects: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load office projects (Status: ${response.statusCode})',
      );
    }
  }

  Future<List<Review>> getOfficeReviews(int officeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$officeId/officereviews'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      // استخدام ReviewModel.fromJson الخاص بكِ
      return data
          .map(
            (reviewJson) => Review.fromJson(reviewJson as Map<String, dynamic>),
          )
          .toList();
    } else {
      logger.e(
        'Failed to load office reviews: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load office reviews (Status: ${response.statusCode})',
      );
    }
  }

  Future<Review> addReview({
    // تم تغيير نوع الإرجاع لـ Review
    required int officeId,
    required int rating,
    required String? comment,
  }) async {
    final token = await Session.getToken();
    if (token == null) {
      throw Exception('User not authenticated to add review');
    }

    // تأكدي من أن هذا الـ endpoint صحيح: POST /api/offices/:id/review
    final response = await http.post(
      Uri.parse('$_baseUrl/$officeId/review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating, // الـ API يتوقع rating
        'comment': comment, // الـ API يتوقع comment
      }),
    );

    if (response.statusCode == 201) {
      logger.i('Review added successfully: ${response.body}');
      // الـ API يرجع { message: 'Review created', review: {...} }
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return Review.fromJson(responseData['review'] as Map<String, dynamic>);
    } else {
      final errorBody = response.body;
      logger.e('Failed to add review: ${response.statusCode} $errorBody');
      try {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
        throw Exception(errorJson['message'] ?? 'Failed to add review');
      } catch (_) {
        throw Exception(
          'Failed to add review (Status: ${response.statusCode})',
        );
      }
    }
  }
}
