// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/user_model.dart'; //  المسار إلى UserModel.dart الخاص بك
import '../session.dart'; //  للتوكن
import '../../utils/constants.dart'; //  لـ Constants.baseUrl

// دالة مساعدة لتنظيف الـ request body (كما ناقشناها سابقاً)
Map<String, dynamic> _cleanRequestBody(Map<String, dynamic> data) {
  final Map<String, dynamic> cleanedData = Map.from(data);
  cleanedData.removeWhere((key, value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    return false;
  });
  return cleanedData;
}

class UserService {
  final String _baseUrl =
      Constants.baseUrl; // مثال: 'http://localhost:5000/api'

  // 1. جلب بيانات المستخدم الحالي المسجل
  Future<UserModel> getCurrentUserDetails() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final response = await http.get(
      //  الـ endpoint لديكِ هو /users/me
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // الـ backend route لـ GET /users/me يرجع الآن المستخدم مع profile_image معدل
      return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    } else if (response.statusCode == 404) {
      throw Exception('User profile not found.');
    } else {
      print(
        'Error fetching current user details (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to fetch your profile details.');
    }
  }

  // 2. تحديث بيانات بروفايل المستخدم الحالي
  //    الـ API endpoint لديكِ هو POST /users/me
  Future<UserModel> updateMyProfile(Map<String, dynamic> dataToUpdate) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final cleanedData = _cleanRequestBody(dataToUpdate);

    if (cleanedData.isEmpty) {
      // إذا لم يتم إرسال أي بيانات للتحديث، يمكننا إرجاع البيانات الحالية أو رمي خطأ
      // إرجاع البيانات الحالية يتطلب استدعاء getCurrentUserDetails() مرة أخرى،
      // وهو ما قد لا يكون مرغوباً. رمي خطأ أو إرجاع null قد يكون أفضل.
      // حالياً، سنرمي خطأ إذا لم يكن هناك بيانات.
      print("No data provided to update profile. Returning current data.");
      // return await getCurrentUserDetails(); // أو
      throw Exception("No data provided for update.");
    }

    print(
      "UserService: Updating user profile with data: ${jsonEncode(cleanedData)}",
    );

    final response = await http.post(
      //  استخدام POST كما هو في الـ route الخاص بك
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(cleanedData),
    );

    if (response.statusCode == 200) {
      //  الـ route الخاص بك يرجع 200 عند النجاح
      // الـ backend route لـ POST /users/me يرجع المستخدم المحدث مع profile_image معدل
      return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      String errorMessage = 'Failed to update your profile.';
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        // الـ route الخاص بك يرجع { error: '...' }
        errorMessage =
            responseBody['error'] ?? responseBody['message'] ?? errorMessage;
        if (responseBody['details'] != null &&
            responseBody['details'] is List) {
          errorMessage +=
              "\nDetails: ${(responseBody['details'] as List).join(', ')}";
        }
      } catch (_) {
        // فشل تحليل JSON، استخدم الرسالة الافتراضية
      }
      print(
        'Error updating user profile (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception(errorMessage);
    }
  }

  // (اختياري) دالة لجلب بروفايل مستخدم معين بواسطة ID (عامة)
  // الـ API endpoint لديكِ هو GET /users/:userId
  Future<UserModel> getUserProfileById(int userId) async {
    // هذا الـ endpoint قد لا يتطلب توكن إذا كان عاماً
    // final token = await Session.getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        // إذا كان يتطلب توكن:
        // if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      throw Exception('User not found (ID: $userId).');
    } else {
      print(
        'Error fetching user profile by ID $userId (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to fetch user profile.');
    }
  }
}
