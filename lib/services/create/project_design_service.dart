// services/project_design_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../models/create/project_design_model.dart'; // تأكدي من المسار الصحيح
import '../session.dart';
import '../../utils/constants.dart'; // أو api_config.dart

// دالة مساعدة لتنظيف الـ request body (يمكن وضعها في ملف utils مشترك)
Map<String, dynamic> _cleanRequestBody(Map<String, dynamic> data) {
  final Map<String, dynamic> cleanedData = Map.from(data);
  cleanedData.removeWhere((key, value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true; //  إزالة القوائم الفارغة
    if (value is Map && value.isEmpty) return true; //  إزالة الـ Maps الفارغة
    return false;
  });
  return cleanedData;
}

class ProjectDesignService {
  final String _baseUrl = Constants.baseUrl;
  final Logger logger = Logger();
  // جلب تفاصيل التصميم لمشروع معين
  Future<ProjectDesignModel?> getProjectDesignDetails(int projectId) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/project-designs/$projectId'), //  المسار من الـ route
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // الـ API قد يرجع null إذا لم يتم العثور على تصميم
      if (response.body.isEmpty || response.body.toLowerCase() == "null") {
        return null;
      }
      return ProjectDesignModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      return null; //  لا يوجد تصميم بعد، هذا ليس خطأ
    } else {
      logger.e(
        'Failed to load project design details for project $projectId (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to load project design details.');
    }
  }

  // إنشاء أو تحديث تفاصيل التصميم لمشروع معين (Upsert)
  Future<ProjectDesignModel> saveOrUpdateProjectDesign(
    int projectId,
    ProjectDesignModel designData,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    // تحويل الكائن إلى Map ثم تنظيفه قبل الإرسال
    // toJson() في ProjectDesignModel يجب أن يرجع Map بكل الحقول المطلوبة للـ upsert
    final Map<String, dynamic> requestBody = _cleanRequestBody(
      designData.toJson(),
    );

    //  تأكدي من أن project_id يتم إرساله إذا كان الـ upsert يتوقعه في الـ body
    //  أو إذا كان الـ upsert يعتمد على العلاقة فقط
    // requestBody['project_id'] = projectId; //  قد لا يكون ضرورياً إذا كان الـ backend يضيفه تلقائياً

    logger.i(
      "Saving/Updating project design for project $projectId with data: ${jsonEncode(requestBody)}",
    );

    final response = await http.post(
      //  الـ route هو POST
      Uri.parse('$_baseUrl/project-designs/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    logger.i(
      "Save/Update project design response status: ${response.statusCode}",
    );
    logger.i("Save/Update project design response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // الـ API يرجع { message: '...', design: { ... } }
      if (responseData.containsKey('design')) {
        return ProjectDesignModel.fromJson(
          responseData['design'] as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Project design data not found in response after save/update.',
        );
      }
    } else {
      String errorMessage = 'Failed to save project design details.';
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            responseBody['error'] ?? responseBody['message'] ?? errorMessage;
        if (responseBody['details'] != null) {
          errorMessage +=
              "\nDetails: ${(responseBody['details'] as List).join(', ')}";
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
