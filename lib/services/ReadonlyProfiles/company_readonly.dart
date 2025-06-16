// services/company_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/company_model.dart';
import '../../models/Basic/project_model.dart';
import '../../models/Basic/review_model.dart'; // استخدام ReviewModel الخاص بكِ (الذي اسمه Review)
import '../session.dart'; // للوصول إلى التوكن
import '../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح
import 'package:logger/logger.dart';

class CompanyProfileService {
  static const String _baseUrl = '${Constants.baseUrl}/companies';
  final Logger logger = Logger();

  Future<CompanyModel> getCompanyDetails(int companyId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$companyId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CompanyModel.fromJson(data);
    } else {
      logger.e(
        'Failed to load company details: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load company details (Status: ${response.statusCode})',
      );
    }
  }

  Future<List<ProjectModel>> getCompanyProjects(int companyId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$companyId/projects'));

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
        'Failed to load company projects: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load company projects (Status: ${response.statusCode})',
      );
    }
  }

  Future<List<Review>> getCompanyReviews(int companyId) async {
    // تم تغيير اسم الكلاس لـ ReviewModel
    final response = await http.get(Uri.parse('$_baseUrl/$companyId/reviews'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map(
            (reviewJson) => Review.fromJson(reviewJson as Map<String, dynamic>),
          ) // استخدام ReviewModel.fromJson
          .toList();
    } else {
      logger.e(
        'Failed to load company reviews: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load company reviews (Status: ${response.statusCode})',
      );
    }
  }

  Future<Review> addReview({
    // تم تغيير اسم الكلاس لـ ReviewModel
    required int companyId,
    required int rating,
    required String? comment,
  }) async {
    final token = await Session.getToken();
    if (token == null) {
      throw Exception('User not authenticated to add review');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/$companyId/review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // الـ API يرجع { message: '...', review: {...} }
      return Review.fromJson(
        responseData['review'] as Map<String, dynamic>,
      ); // استخدام ReviewModel.fromJson
    } else {
      final errorBody = response.body;
      logger.e(
        'Failed to add company review: ${response.statusCode} $errorBody',
      );
      try {
        final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
        throw Exception(errorJson['message'] ?? 'Failed to add company review');
      } catch (_) {
        throw Exception(
          'Failed to add company review (Status: ${response.statusCode})',
        );
      }
    }
  }
} // TODO Implement this library.
