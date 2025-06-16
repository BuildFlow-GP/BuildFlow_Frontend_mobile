// services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/notifications_model.dart'; // تأكدي من المسار
import '../session.dart';
import '../../utils/constants.dart'; // افترض أن لديك هذا لـ baseUrl

class NotificationService {
  final String _baseUrl =
      Constants.baseUrl; // مثال: 'http://localhost:5000/api'

  Future<NotificationListResponse> getMyNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      // يمكنك رمي خطأ أو إرجاع قائمة فارغة مع totalItems = 0
      // throw Exception('Authentication token not found. Please log in.');
      return NotificationListResponse(
        totalItems: 0,
        notifications: [],
        currentPage: 1,
        totalPages: 0,
      );
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/my?limit=$limit&offset=$offset'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return NotificationListResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    } else {
      print(
        'Failed to load notifications (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to load your notifications.');
    }
  }

  Future<NotificationModel?> markNotificationAsRead(int notificationId) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseBody['notification'] != null) {
        return NotificationModel.fromJson(
          responseBody['notification'] as Map<String, dynamic>,
        );
      }
      return null; // أو أرجعي رسالة النجاح إذا لم يكن الإشعار مرجعاً
    } else {
      print(
        'Failed to mark notification $notificationId as read (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to mark notification as read.');
    }
  }

  Future<int> markAllNotificationsAsRead() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/mark-all-as-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['count'] as int? ??
          0; // عدد الإشعارات التي تم تحديثها
    } else {
      print(
        'Failed to mark all notifications as read (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to mark all notifications as read.');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      return 0; // إذا لم يكن مسجلاً، لا يوجد إشعارات غير مقروءة
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['unreadCount'] as int? ?? 0;
    } else {
      print(
        'Failed to get unread notification count (Status: ${response.statusCode}): ${response.body}',
      );
      // لا ترمي خطأ هنا، فقط أرجعي 0 إذا فشل، حتى لا يتعطل الـ UI
      return 0;
    }
  }

  // دالة لإنشاء إشعار (إذا احتجتِ لاستدعائها من Flutter، وهو أمر غير شائع)
  // يجب التأكد من أن الـ backend يسمح بذلك ويحميه بشكل مناسب
  Future<NotificationModel> createNotification(
    Map<String, dynamic> notificationData,
  ) async {
    // final token = await Session.getToken(); // قد يتطلب توكن
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications'),
      // headers: {
      //   'Content-Type': 'application/json',
      //   if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      // },
      body: jsonEncode(notificationData),
    );
    if (response.statusCode == 201) {
      return NotificationModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to create notification.');
    }
  }
}
