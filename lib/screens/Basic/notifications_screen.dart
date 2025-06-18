// screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:get/get.dart'; // إذا كنتِ ستستخدمينه للانتقال

import '../../services/Basic/notifications_service.dart';
import '../../models/Basic/notifications_model.dart';
import '../../utils/constants.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';

// استيراد صفحات التفاصيل والانتقال إليها
import '../ReadonlyProfiles/office_readonly_profile.dart';
import '../ReadonlyProfiles/company_readonly_profile.dart';
import '../ReadonlyProfiles/project_readonly_profile.dart'; // تأكد من وجوده ومساره الصحيح
import 'package:logger/logger.dart';
// إضافة سيرفس المشروع
import '../../services/create/project_service.dart'; // تأكد من وجوده ومساره الصحيح

// شاشات سيتم الانتقال إليها بناءً على الإجراء (للمستخدم)
import '../design/my_project_details.dart';
import '../design/no_permit_screen.dart'; // شاشة استكمال البيانات بعد موافقة المكتب، تأكد من وجودها ومسارها
import '../design/choose_office.dart';
import '../super/project_details_super.dart';
import '../super/select_company_supervision.dart'; // شاشة اختيار مكتب آخر عند الرفض، تأكد من وجودها ومسارها

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ProjectService _projectService = ProjectService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  bool _isProcessingAction = false; // لمنع الضغط المتكرر على الأزرار
  final ScrollController _scrollController = ScrollController();
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // عدد الأسطر في كل سجل
      colors: true, // تلوين السجلات
      printEmojis: true, // طباعة الرموز التعبيرية
      // ignore: deprecated_member_use
      printTime: true, // طباعة الوقت
    ),
  );
  // مجموعة لتخزين IDs الإشعارات التي تم التعامل معها (Approve/Reject)
  final Set<int> _processedNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications(isRefresh: true);
    _scrollController.addListener(() {
      // التحقق من الوصول إلى نهاية القائمة لجلب المزيد من الإشعارات
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent -
                  200 && // قرب النهاية بـ 200 بكسل
          _currentPage < _totalPages && // لم نصل بعد إلى آخر صفحة
          !_isLoading && // لا يوجد تحميل حالي
          !_isFetchingMore) {
        // لا يوجد جلب بيانات حالي
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!mounted) return;
    if (_isFetchingMore && !isRefresh) {
      return; // لا تجلب المزيد إذا كان الجلب قيد التقدم ولم يكن تحديثًا
    }

    setState(() {
      if (isRefresh) {
        // تهيئة الحالة عند التحديث
        _isLoading = true;
        _error = null;
        _notifications = [];
        _currentPage = 1;
        _totalPages = 1;
        _processedNotificationIds.clear(); // مسح الإشعارات المعالجة عند التحديث
      } else {
        _isFetchingMore = true; // تعيين حالة الجلب للمزيد
      }
    });

    try {
      final response = await _notificationService.getMyNotifications(
        // حساب الـ offset بناءً على الصفحة الحالية والـ limit
        offset: (isRefresh ? 0 : (_currentPage - 1)) * 20,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _notifications = response.notifications;
          } else {
            _notifications.addAll(
              response.notifications,
            ); // إضافة الإشعارات الجديدة
          }
          _totalPages = response.totalPages;
          if (!isRefresh && response.notifications.isNotEmpty) {
            _currentPage++; // زيادة رقم الصفحة إذا تم جلب بيانات جديدة
          } else if (isRefresh && response.notifications.isNotEmpty) {
            _currentPage = 1; // إعادة تعيين الصفحة الأولى عند التحديث
            if (response.totalPages == 0 && response.totalItems > 0) {
              _totalPages =
                  1; // تأكد من أن هناك صفحة واحدة على الأقل إذا كان هناك عناصر
            }
          } else if (isRefresh && response.notifications.isEmpty) {
            _currentPage =
                1; // إذا لم تكن هناك إشعارات بعد التحديث، ابدأ من الصفحة 1 و Total 0
            _totalPages = 0;
          }

          _isLoading = false;
          _isFetchingMore = false;
          _error = null; // مسح الأخطاء
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
      debugPrint("Error loading notifications: $e");
    }
  }

  // دالة لمعالجة الضغط على أيقونة "Mark as Read"
  Future<void> _handleMarkAsReadIconTap(NotificationModel notification) async {
    if (notification.isRead || _isProcessingAction) {
      return; // لا تفعل شيئًا إذا كان مقروءًا أو عملية أخرى قيد التقدم
    }
    setState(() => _isProcessingAction = true); // إظهار التحميل
    try {
      final updatedNotification = await _notificationService
          .markNotificationAsRead(notification.id);
      if (updatedNotification != null && mounted) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] =
                updatedNotification; // تحديث الإشعار في القائمة
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: ${e.toString()}'),
            backgroundColor: AppColors.error, // لون الخطأ من AppColors
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false); // إخفاء التحميل
    }
  }

  // دالة لتمييز جميع الإشعارات كمقروءة
  Future<void> _markAllAsRead() async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true); // إظهار التحميل
    try {
      final count = await _notificationService.markAllNotificationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count notifications marked as read.'),
            backgroundColor: AppColors.success, // لون النجاح من AppColors
          ),
        );
        _loadNotifications(
          isRefresh: true,
        ); // إعادة تحميل الإشعارات بعد التحديث
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: ${e.toString()}'),
            backgroundColor: AppColors.error, // لون الخطأ من AppColors
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false); // إخفاء التحميل
    }
  }

  // دالة لتمييز الإشعار كمقروء ثم تنفيذ إجراء معين
  Future<void> _markAsReadAndThen(
    NotificationModel notification,
    Future<void> Function() onReadCompleteActionAsync,
  ) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true); // إظهار التحميل

    // دالة مساعدة لتنفيذ الإجراء بعد التمييز كمقروء أو إذا كان مقروءًا بالفعل
    Future<void> executeActionAfterReadLogic() async {
      try {
        await onReadCompleteActionAsync();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action failed: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        debugPrint("Error during onReadCompleteActionAsync: $e");
      } finally {
        if (mounted && _isProcessingAction) {
          setState(() => _isProcessingAction = false); // إخفاء التحميل
        }
      }
    }

    if (notification.isRead) {
      // إذا كان الإشعار مقروءًا بالفعل، نفذ الإجراء مباشرة
      await executeActionAfterReadLogic();
      return;
    }
    // إذا لم يكن مقروءًا، قم بتمييزه كمقروء أولاً ثم نفذ الإجراء
    try {
      final updatedNotification = await _notificationService
          .markNotificationAsRead(notification.id);
      if (updatedNotification != null && mounted) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notification.id,
          );
          if (index != -1) {
            _notifications[index] =
                updatedNotification; // تحديث الإشعار في القائمة
          }
        });
        await executeActionAfterReadLogic(); // نفذ الإجراء بعد التحديث
      } else {
        // إذا فشل تمييز الإشعار كمقروء
        if (mounted) setState(() => _isProcessingAction = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark as read before action: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _handleSupervisionRequestResponse(
    NotificationModel notification,
    String action,
  ) async {
    if (notification.targetEntityId == null ||
        notification.targetEntityType != 'project' ||
        _isProcessingAction) {
      logger.w(
        "Cannot $action supervision: Invalid notification target or action in progress.",
      );
      return;
    }

    // سيتم تعليم الإشعار كمقروء كجزء من _markAsReadAndThen
    await _markAsReadAndThen(notification, () async {
      try {
        // استدعاء دالة السيرفس من ProjectService
        // respondToSupervisionRequest (التي أنشأناها سابقاً بناءً على طلبك للـ backend)
        await _projectService.respondToSupervisionRequest(
          notification.targetEntityId!,
          action,
          // rejectionReason: إذا كان الـ action هو 'reject' وتريدين إضافة سبب (يتطلب تعديل UI)
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Supervision request has been ${action}ed successfully.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          // إضافة ID الإشعار إلى قائمة المعالجة لإخفاء الأزرار
          setState(() {
            _processedNotificationIds.add(notification.id);
            //  يمكنكِ أيضاً إزالة الإشعار من القائمة إذا أردتِ بدلاً من إخفاء الأزرار فقط
            // _notifications.removeWhere((n) => n.id == notification.id);
          });
          // أو إعادة تحميل القائمة بالكامل
          // _loadNotifications(isRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to $action supervision request: ${e.toString()}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        logger.e(
          "Error ${action}ing supervision request for project ${notification.targetEntityId}",
          error: e,
        );
      }
    });
  }

  // دالة لتنفيذ إجراءات المستخدم (بعد موافقة/رفض المكتب)
  // ignore: unused_element
  Future<void> _performUserResponseAction(
    NotificationModel notification,
  ) async {
    await _markAsReadAndThen(
      notification,
      () async => _proceedWithUserOrGeneralAction(notification),
    );
  }

  Future<void> _proceedWithUserOrGeneralAction(
    NotificationModel notification,
  ) async {
    if (!mounted) return;
    if (notification.targetEntityId == null ||
        notification.targetEntityType == null) {
      debugPrint("Notification action: No target entity.");
      return;
    }
    Widget? targetScreen;
    String? routeDescription;

    switch (notification.notificationType) {
      // --- حالات خاصة بالمستخدم ---
      case 'PROJECT_APPROVED_BY_OFFICE': // هذا إشعار للمستخدم بأن مكتب التصميم وافق
        targetScreen = NoPermitScreen(projectId: notification.targetEntityId!);
        routeDescription =
            "Complete project (ID: ${notification.targetEntityId}) details after design office approval";
        break;
      case 'PROJECT_REJECTED_BY_OFFICE': // هذا إشعار للمستخدم بأن مكتب التصميم رفض
        targetScreen = const ChooseOfficeScreen(); // شاشة اختيار مكتب تصميم آخر
        routeDescription =
            "Choose another design office for project (ID: ${notification.targetEntityId})";
        break;
      // ✅✅✅ حالات جديدة خاصة بمسار الإشراف (للمستخدم) ✅✅✅
      case 'SUPERVISION_REQUEST_APPROVED':
        targetScreen = ProjectSupervisionDetailsScreen(
          projectId: notification.targetEntityId!,
        );
        routeDescription =
            "View supervised project (ID: ${notification.targetEntityId})";
        break;
      case 'SUPERVISION_REQUEST_REJECTED':
        // المستخدم ينتقل لاختيار مكتب إشراف آخر
        // ستحتاجين لشاشة اختيار مكتب مخصصة للإشراف أو تمرير معامل لـ ChooseOfficeScreen
        targetScreen = SelectCompanyForSupervisionScreen(
          projectId: notification.targetEntityId!,
        ); //  مثال: معامل جديد
        routeDescription =
            "Choose another supervising office for project (ID: ${notification.targetEntityId})";
        break;
      // --- حالات عامة أو للمكتب ---
      case 'OFFICE_UPLOADED_2D_DOCUMENT':
      case 'OFFICE_UPLOADED_3D_DOCUMENT':
      case 'USER_SUBMITTED_PROJECT_DETAILS': //  إشعار للمكتب
      case 'OFFICE_PROPOSED_PAYMENT': // إشعار للمستخدم
      case 'PROJECT_PROGRESS_UPDATED': // إشعار للمستخدم
        targetScreen = ProjectDetailsViewScreen(
          projectId: notification.targetEntityId!,
        );
        routeDescription =
            "View project (ID: ${notification.targetEntityId}) details/updates";
        break;
      // NEW_PROJECT_REQUEST (للمكتب) لا يتم التعامل معه هنا، بل بأزرار Approve/Reject مباشرة
      // NEW_SUPERVISION_REQUEST (للمكتب) لا يتم التعامل معه هنا، بل بأزرار Approve/Reject مباشرة
      default:
        debugPrint(
          "No specific general action defined for notification type: ${notification.notificationType}",
        );
        await _navigateToTargetEntity(notification, skipMarkAsRead: true);
        return;
    }

    debugPrint("Navigating to: $routeDescription");
    if (!mounted) return;
    //  استخدمي Navigator.push، وإذا أردتِ إرجاع قيمة لتحديث، استخدمي then
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen!),
    );
    //  يمكنكِ عمل _loadNotifications(isRefresh: true) هنا إذا أردتِ تحديث القائمة دائماً بعد العودة
  } // دالة لمعالجة رد المكتب على طلب مشروع (قبول/رفض)

  Future<void> _handleProjectRequestResponse(
    NotificationModel notification,
    String action, // 'approve' أو 'reject'
  ) async {
    if (notification.targetEntityId == null ||
        notification.targetEntityType != 'project' ||
        _isProcessingAction) {
      return;
    }
    await _markAsReadAndThen(notification, () async {
      try {
        await _projectService.respondToProjectRequest(
          notification.targetEntityId!,
          action,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Project request has been ${action}ed successfully.',
              ),
              backgroundColor: AppColors.success, // لون النجاح من AppColors
            ),
          );
          setState(() {
            _processedNotificationIds.add(
              notification.id,
            ); // إضافة الإشعار إلى قائمة المعالجة
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to $action project request: ${e.toString()}',
              ),
              backgroundColor: AppColors.error, // لون الخطأ من AppColors
            ),
          );
        }
        debugPrint("Error ${action}ing project request: $e");
      }
    });
  }

  // دالة عامة لتنفيذ إجراءات المستخدم أو الإجراءات العامة
  Future<void> _performUserOrGeneralAction(
    NotificationModel notification,
  ) async {
    // هذه الدالة ستنفذ الإجراء المحدد بعد تمييز الإشعار كمقروء
    await _markAsReadAndThen(
      notification,
      () async => _proceedWithUserOrGeneralAction(notification),
    );
  }

  // دالة عامة للانتقال إلى صفحة تفاصيل الكيان المستهدف
  Future<void> _navigateToTargetEntity(
    NotificationModel notification, {
    bool skipMarkAsRead =
        false, // لتخطي تمييز الإشعار كمقروء إذا تم التعامل معه بطريقة أخرى
  }) async {
    Future<void> navigateAction() async {
      if (!mounted) return;
      if (notification.targetEntityId == null ||
          notification.targetEntityType == null) {
        return;
      }
      Widget? targetScreen;
      switch (notification.targetEntityType!.toLowerCase()) {
        case 'project':
          targetScreen = ProjectreadDetailsScreen(
            projectId: notification.targetEntityId!,
          );
          break;
        case 'office_profile':
        case 'office':
          targetScreen = OfficerProfileScreen(
            officeId: notification.targetEntityId!,
          );
          break;
        case 'company_profile':
        case 'company':
          targetScreen = CompanyrProfileScreen(
            companyId: notification.targetEntityId!,
          );
          break;
        default:
          debugPrint(
            "Unknown target entity type for navigation: ${notification.targetEntityType}",
          );
      }
      if (targetScreen != null) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen!),
        );
      }
    }

    if (skipMarkAsRead || notification.isRead) {
      await navigateAction();
    } else {
      await _markAsReadAndThen(notification, navigateAction);
    }
  }

  // دالة لتنسيق الوقت بصيغة "منذ كذا"
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(
      dateTime.toLocal(),
    ); // التأكد من استخدام الوقت المحلي

    if (difference.inSeconds < 5) return 'just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat(
      'dd MMM, yyyy',
    ).format(dateTime.toLocal()); // تنسيق كامل للتاريخ بعد أسبوع
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final timeAgo = _formatTimeAgo(notification.createdAt);
    ImageProvider? actorImageProvider;
    IconData actorDefaultIcon = Icons.person_outline;

    if (notification.actor?.profileImage != null &&
        notification.actor!.profileImage!.isNotEmpty) {
      actorImageProvider = NetworkImage(
        notification.actor!.profileImage!.startsWith('http')
            ? notification.actor!.profileImage!
            : '${Constants.baseUrl}/${notification.actor!.profileImage}',
      );
    } else if (notification.actor != null) {
      switch (notification.actor!.type.toLowerCase()) {
        case 'office':
          actorDefaultIcon = Icons.maps_home_work_outlined;
          break;
        case 'company':
          actorDefaultIcon = Icons.apartment_outlined;
          break;
        case 'individual':
        default:
          actorDefaultIcon = Icons.person_outline;
          break;
      }
    }

    // ✅✅✅ تحديد إذا كان الإشعار هو طلب إشراف جديد للمكتب ولم يتم التعامل معه بعد ✅✅✅
    bool isNewSupervisionRequestForOffice =
        notification.notificationType == 'NEW_SUPERVISION_REQUEST' &&
        !_processedNotificationIds.contains(notification.id) &&
        notification.recipientType ==
            'office'; // تأكدي أن هذا الإشعار موجه للمكتب

    // تحديد إذا كان الإشعار هو طلب تصميم جديد للمكتب (من الكود السابق)
    bool isNewDesignRequestForOffice =
        notification.notificationType == 'NEW_PROJECT_REQUEST' &&
        !_processedNotificationIds.contains(notification.id) &&
        notification.recipientType == 'office';

    // تحديد إذا كان الإشعار هو رد على طلب (للمستخدم)
    bool isProjectResponseForUser =
        (notification.notificationType == 'PROJECT_APPROVED_BY_OFFICE' ||
            notification.notificationType == 'PROJECT_REJECTED_BY_OFFICE' ||
            notification.notificationType ==
                'SUPERVISION_REQUEST_APPROVED' || // ✅
            notification.notificationType ==
                'SUPERVISION_REQUEST_REJECTED') && // ✅
        notification.recipientType == 'individual';

    String? generalActionButtonText;
    IconData? generalActionButtonIcon;

    // زر الإجراء العام (إذا لم يكن أياً من الحالات الخاصة أعلاه)
    if (!isNewSupervisionRequestForOffice &&
        !isNewDesignRequestForOffice &&
        !isProjectResponseForUser) {
      switch (notification.notificationType) {
        case 'OFFICE_UPLOADED_2D_DOCUMENT':
        case 'OFFICE_UPLOADED_3D_DOCUMENT':
        case 'USER_SUBMITTED_PROJECT_DETAILS': // إشعار للمكتب ليرى التفاصيل
        case 'OFFICE_PROPOSED_PAYMENT': // إشعار للمستخدم ليرى اقتراح الدفع
        case 'PROJECT_PROGRESS_UPDATED': // إشعار للمستخدم بتحديث التقدم
          generalActionButtonText = 'View Details';
          generalActionButtonIcon = Icons.visibility_outlined;
          break;
      }
    }

    return Material(
      color:
          notification.isRead
              ? Theme.of(context).cardColor
              : Theme.of(context).highlightColor.withOpacity(0.5),
      child: InkWell(
        onTap: () => _navigateToTargetEntity(notification),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24, // حجم أكبر قليلاً
                backgroundImage: actorImageProvider,
                backgroundColor: AppColors.background, // لون خلفية من AppColors
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('Error loading actor image: $exception');
                },
                child:
                    actorImageProvider == null
                        ? Icon(
                          actorDefaultIcon,
                          size: 24, // حجم أيقونة أكبر
                          color: AppColors.textSecondary, // لون من AppColors
                        )
                        : null,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الممثل
                    Text(
                      notification.actor?.name ??
                          'System', // 'System' كقيمة افتراضية
                      style: TextStyle(
                        fontWeight: FontWeight.w700, // خط أثقل
                        fontSize: 16,
                        color:
                            notification.isRead
                                ? AppColors
                                    .textSecondary // لون نص المقروء
                                : AppColors.textPrimary, // لون نص غير المقروء
                      ),
                    ),
                    const SizedBox(height: 4),
                    // رسالة الإشعار
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            notification.isRead
                                ? AppColors.textSecondary.withOpacity(
                                  0.8,
                                ) // لون نص المقروء
                                : AppColors.textPrimary, // لون نص غير المقروء
                        fontWeight:
                            notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w500, // خط أثقل لغير المقروء
                      ),
                      maxLines: 3, // عرض 3 أسطر كحد أقصى
                      overflow:
                          TextOverflow.ellipsis, // إضافة ... إذا تجاوز النص
                    ),
                    const SizedBox(height: 8),
                    // ✅✅✅ عرض الأزرار بناءً على نوع الإشعار والسيناريو ✅✅✅
                    if (isNewDesignRequestForOffice) // أزرار للمكتب للرد على طلب تصميم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon:
                                _isProcessingAction
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                    ),
                            label: Text(
                              _isProcessingAction
                                  ? "Wait..."
                                  : "Approve Design",
                            ),
                            onPressed:
                                _isProcessingAction
                                    ? null
                                    : () => _handleProjectRequestResponse(
                                      notification,
                                      'approve',
                                    ), //  يستدعي API رد المكتب على طلب التصميم
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon:
                                _isProcessingAction
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.cancel_outlined,
                                      size: 16,
                                    ),
                            label: Text(
                              _isProcessingAction ? "Wait..." : "Reject Design",
                            ),
                            onPressed:
                                _isProcessingAction
                                    ? null
                                    : () => _handleProjectRequestResponse(
                                      notification,
                                      'reject',
                                    ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade400),
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isNewSupervisionRequestForOffice) //  ✅ أزرار للمكتب للرد على طلب إشراف
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            icon:
                                _isProcessingAction
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.playlist_add_check_circle_outlined,
                                      size: 16,
                                    ),
                            label: Text(
                              _isProcessingAction
                                  ? "Wait..."
                                  : "Approve Supervision",
                            ),
                            onPressed:
                                _isProcessingAction
                                    ? null
                                    : () => _handleSupervisionRequestResponse(
                                      notification,
                                      'approve',
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon:
                                _isProcessingAction
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.highlight_off_outlined,
                                      size: 16,
                                    ),
                            label: Text(
                              _isProcessingAction
                                  ? "Wait..."
                                  : "Reject Supervision",
                            ),
                            onPressed:
                                _isProcessingAction
                                    ? null
                                    : () => _handleSupervisionRequestResponse(
                                      notification,
                                      'reject',
                                    ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isProjectResponseForUser) // زر للمستخدم للانتقال بعد موافقة/رفض المكتب
                      TextButton.icon(
                        icon: Icon(
                          (notification.notificationType ==
                                      'PROJECT_APPROVED_BY_OFFICE' ||
                                  notification.notificationType ==
                                      'SUPERVISION_REQUEST_APPROVED')
                              ? Icons.arrow_forward_rounded
                              : Icons.find_in_page_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          (notification.notificationType ==
                                      'PROJECT_APPROVED_BY_OFFICE' ||
                                  notification.notificationType ==
                                      'SUPERVISION_REQUEST_APPROVED')
                              ? (notification.notificationType ==
                                      'PROJECT_APPROVED_BY_OFFICE'
                                  ? 'Complete Project Info'
                                  : 'View Supervised Project')
                              : 'Choose Another Office',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onPressed:
                            _isProcessingAction
                                ? null
                                : () =>
                                    _performUserOrGeneralAction(notification),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else if (generalActionButtonText !=
                        null) // زر الإجراء العام لأنواع أخرى
                      TextButton.icon(
                        icon: Icon(
                          generalActionButtonIcon ?? Icons.visibility_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        label: Text(
                          generalActionButtonText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        onPressed:
                            _isProcessingAction
                                ? null
                                : () =>
                                    _performUserOrGeneralAction(notification),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4.0),
              SizedBox(
                width: 36, // حجم ثابت للأيقونة
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    notification.isRead
                        ? Icons
                            .check_circle_rounded // أيقونة مقروء
                        : Icons.circle_outlined, // أيقونة غير مقروء
                    color:
                        notification.isRead
                            ? AppColors
                                .success // لون النجاح من AppColors
                            : AppColors.primary, // لون رئيسي من AppColors
                    size: 24, // حجم أيقونة أكبر
                  ),
                  tooltip: notification.isRead ? 'Read' : 'Mark as Read',
                  onPressed:
                      (notification.isRead ||
                              _isProcessingAction) // زر معطل إذا كان مقروءًا أو عملية قيد التقدم
                          ? null
                          : () => _handleMarkAsReadIconTap(notification),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ضبط عرض المحتوى بناءً على حجم الشاشة (متجاوب)
    double screenWidth = MediaQuery.of(context).size.width;
    // أقصى عرض 800px في الشاشات الكبيرة، أو 100% من عرض الشاشة في الموبايل
    double contentMaxWidth = screenWidth > 800 ? 800 : screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background, // خلفية الشاشة من AppColors
      // AppBar مخصص بتصميم متناسق مع باقي الشاشات
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0), // ارتفاع AppBar المخصص
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            40,
            16,
            20,
          ), // Padding أعلى لأزرار الحالة (Status bar)
          decoration: BoxDecoration(
            color: AppColors.primary, // لون خلفية AppBar من AppColors
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2), // ظل أغمق
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications', // عنوان الصفحة
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent, // لون العنوان من AppColors
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // أزرار الإجراءات في الـ AppBar
              if (_notifications.any(
                    (n) => !n.isRead,
                  ) && // إظهار الزر فقط إذا كان هناك إشعارات غير مقروءة
                  !_isLoading && // لا يوجد تحميل عام
                  !_isFetchingMore) // لا يوجد جلب المزيد من البيانات
                SizedBox(
                  // استخدام SizedBox لضمان حجم ثابت للزر
                  width: 48, // حجم ثابت ليتناسق مع زر الرجوع
                  height: 48,
                  child: TextButton(
                    onPressed:
                        _isProcessingAction
                            ? null
                            : _markAllAsRead, // زر معطل إذا كان هناك عملية قيد التقدم
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // إزالة Padding الافتراضي
                      alignment: Alignment.center, // توسيط النص والأيقونة
                    ),
                    child:
                        _isProcessingAction
                            ? CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ), // لون مؤشر التحميل
                            )
                            : Icon(
                              Icons
                                  .done_all_rounded, // أيقونة "تمييز الكل كمقروء"
                              color:
                                  AppColors.accent, // لون الأيقونة من AppColors
                              size: 24,
                            ),
                  ),
                )
              else
                const SizedBox(width: 48), // مسافة فارغة لتوازن زر الرجوع
            ],
          ),
        ),
      ),
      body: Center(
        // توسيط المحتوى أفقياً
        child: ConstrainedBox(
          // تحديد عرض أقصى للمحتوى ليكون متجاوباً (Responsive)
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth,
          ), // استخدام العرض المتجاوب
          child: _buildBody(), // بناء محتوى الشاشة
        ),
      ),
    );
  }

  // دالة بناء جسم الشاشة (حالات التحميل، الخطأ، النتائج)
  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primary,
          ), // لون من AppColors
        ),
      );
    }
    if (_error != null && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 60,
              ), // أيقونة خطأ بلون AppColors
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.error, // لون نص الخطأ من AppColors
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                onPressed: () => _loadNotifications(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // لون الزر من AppColors
                  foregroundColor: AppColors.background, // لون نص الزر
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: AppColors.textSecondary, // لون من AppColors
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'You have no notifications yet.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary, // لون من AppColors
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for updates.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, // لون من AppColors
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                onPressed: () => _loadNotifications(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // لون الزر من AppColors
                  foregroundColor: AppColors.background, // لون نص الزر
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadNotifications(isRefresh: true),
      child: ListView.separated(
        controller: _scrollController,
        itemCount:
            _notifications.length +
            (_isFetchingMore ? 1 : 0), // إضافة عنصر للتحميل إذا كنا نجلب المزيد
        itemBuilder: (context, index) {
          // عرض مؤشر تحميل في نهاية القائمة عند جلب المزيد
          if (index == _notifications.length && _isFetchingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ), // لون من AppColors
                ),
              ),
            );
          }
          if (index >= _notifications.length) {
            return const SizedBox.shrink(); // تجنب أي تجاوزات
          }

          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
        separatorBuilder:
            (context, index) => Divider(
              height: 0,
              thickness: 0.8, // سمك أكبر قليلاً للفاصل
              color: AppColors.primary.withOpacity(
                0.3,
              ), // لون فاصل من AppColors
              indent: 70, // المسافة البادئة
              endIndent: 16, // المسافة النهائية
            ),
      ),
    );
  }
}
