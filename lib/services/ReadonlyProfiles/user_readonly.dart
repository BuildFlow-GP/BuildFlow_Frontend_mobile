// services/user_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/user_model.dart'; // تأكدي من المسار الصحيح
import '../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح

class UserProfileService {
  // استخدمي نفس الـ baseUrl من الـ backend
  // وافترض أن مسار المستخدمين هو /api/users
  static const String _baseUrl = '${Constants.baseUrl}/users';

  // لجلب تفاصيل مستخدم معين (للعرض العام)
  Future<UserModel> getUserDetails(int userId) async {
    // لا حاجة لتوكن هنا لأن هذا endpoint عام (حسب ما عدلناه)
    final response = await http.get(Uri.parse('$_baseUrl/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      print(
        'Failed to load user details: ${response.statusCode} ${response.body}',
      );
      throw Exception(
        'Failed to load user details (Status: ${response.statusCode})',
      );
    }
  }
}
