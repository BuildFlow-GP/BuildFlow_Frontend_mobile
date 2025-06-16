// models/notification_model.dart

class ActorModel {
  final int id;
  final String name;
  final String? profileImage; // قد يكون null
  final String type; // 'individual', 'office', 'company'

  ActorModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.type,
  });

  factory ActorModel.fromJson(Map<String, dynamic> json) {
    return ActorModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Actor', // قيمة افتراضية
      profileImage: json['profile_image'] as String?,
      type: json['type'] as String? ?? 'unknown', // قيمة افتراضية
    );
  }
}

// models/notification_model.dart
class NotificationModel {
  final int id;
  final int recipientId;
  final String recipientType; // 'individual', 'office', 'company'
  final int? actorId;
  final String? actorType; // 'individual', 'office', 'company'
  final String notificationType; // e.g., 'NEW_PROJECT_REQUEST'
  final String message;
  final int? targetEntityId;
  final String? targetEntityType; // 'project', 'review', etc.
  bool isRead; // قابلة للتعديل
  final DateTime? readAt;
  final DateTime createdAt;
  final ActorModel? actor; // كائن الـ Actor المدمج

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    this.actorId,
    this.actorType,
    required this.notificationType,
    required this.message,
    this.targetEntityId,
    this.targetEntityType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.actor,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة لتحويل النصوص إلى DateTime بأمان
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date string: $dateString, error: $e");
        return null; // أو أرجعي DateTime.now() كقيمة افتراضية إذا كان created_at مطلوباً دائماً
      }
    }

    return NotificationModel(
      id: json['id'] as int,
      recipientId: json['recipient_id'] as int,
      recipientType: json['recipient_type'] as String,
      actorId: json['actor_id'] as int?,
      actorType: json['actor_type'] as String?,
      notificationType: json['notification_type'] as String,
      message: json['message'] as String,
      targetEntityId: json['target_entity_id'] as int?,
      targetEntityType: json['target_entity_type'] as String?,
      isRead: json['is_read'] as bool? ?? false, // قيمة افتراضية
      readAt: parseDate(json['read_at'] as String?),
      createdAt:
          parseDate(json['created_at'] as String?) ??
          DateTime.now(), // قيمة افتراضية قوية
      actor:
          json['actor'] != null
              ? ActorModel.fromJson(json['actor'] as Map<String, dynamic>)
              : null,
    );
  }
}

// (اختياري ولكن موصى به) موديل للـ Response الكامل من API جلب الإشعارات
class NotificationListResponse {
  final int totalItems;
  final List<NotificationModel> notifications;
  final int currentPage;
  final int totalPages;

  NotificationListResponse({
    required this.totalItems,
    required this.notifications,
    required this.currentPage,
    required this.totalPages,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    var notificationsListJson = json['notifications'] as List<dynamic>? ?? [];
    List<NotificationModel> notifications =
        notificationsListJson
            .map((i) => NotificationModel.fromJson(i as Map<String, dynamic>))
            .toList();

    return NotificationListResponse(
      totalItems: json['totalItems'] as int? ?? 0,
      notifications: notifications,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
