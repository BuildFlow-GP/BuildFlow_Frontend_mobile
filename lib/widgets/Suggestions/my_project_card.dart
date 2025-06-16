// widgets/my_project_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لـ DateFormat
// import '../../models/userprojects/project_simplified_model.dart';
import '../../utils/constants.dart'; // لمسار الصور (إذا لزم الأمر)

class MyProjectCard extends StatelessWidget {
  final dynamic project;
  final VoidCallback? onTap;

  const MyProjectCard({super.key, required this.project, this.onTap});

  // دالة مساعدة لتحديد لون الحالة
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
      case 'inprogress': // للتعامل مع احتمالات مختلفة
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    String displayDate =
        project.startDate != null
            ? 'Started: ${dateFormat.format(project.startDate!)}'
            : 'Created: ${dateFormat.format(project.createdAt)}';

    ImageProvider? entityImageProvider;
    String? entityName;
    IconData entityIcon = Icons.business_outlined; // أيقونة افتراضية

    if (project.office != null) {
      entityName = project.office!.name;
      if (project.office!.profileImage != null &&
          project.office!.profileImage!.isNotEmpty) {
        entityImageProvider = NetworkImage(
          project.office!.profileImage!.startsWith('http')
              ? project.office!.profileImage!
              : '${Constants.baseUrl}/${project.office!.profileImage}',
        ); // تأكدي من ApiConfig
      }
      entityIcon = Icons.maps_home_work_outlined; // أيقونة المكتب
    } else if (project.company != null) {
      entityName = project.company!.name;
      if (project.company!.profileImage != null &&
          project.company!.profileImage!.isNotEmpty) {
        entityImageProvider = NetworkImage(
          project.company!.profileImage!.startsWith('http')
              ? project.company!.profileImage!
              : '${Constants.baseUrl}/${project.company!.profileImage}',
        );
      }
      entityIcon = Icons.apartment_outlined; // أيقونة الشركة
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      project.status,
                      style: TextStyle(
                        color: _getStatusColor(project.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                displayDate,
                style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12.0),
              if (entityName != null)
                Row(
                  children: [
                    if (entityImageProvider != null)
                      CircleAvatar(
                        backgroundImage: entityImageProvider,
                        radius: 16,
                        onBackgroundImageError:
                            (_, __) {}, // معالجة خطأ تحميل الصورة بصمت
                        backgroundColor:
                            Colors.grey[200], // لون خلفية إذا فشلت الصورة
                        child:
                            // ignore: unnecessary_null_comparison
                            entityImageProvider == null
                                ? Icon(
                                  entityIcon,
                                  size: 18,
                                  color: Colors.grey[600],
                                )
                                : null,
                      )
                    else
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          entityIcon,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        entityName,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (entityName == null &&
                  project.location != null &&
                  project.location!.isNotEmpty)
                Row(
                  // عرض الموقع إذا لم يكن هناك مكتب أو شركة
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        project.location!,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // يمكنكِ إضافة المزيد من التفاصيل أو الأزرار هنا إذا أردتِ
            ],
          ),
        ),
      ),
    );
  }
}
