// widgets/project_sections/design_details_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; //  لـ currencyFormat
import '../../models/Basic/project_model.dart';
import '../../models/create/project_design_model.dart';
import '../../themes/app_colors.dart'; //  لـ AppColors
//  افترض أن لديك هذه الدوال المساعدة معرفة في مكان ما (utils أو في نفس الملف مؤقتاً)
//  أو يمكنكِ تمريرها كمعاملات إذا كانت معقدة وتعتمد على حالة الشاشة الأم
//  _buildInfoRow, _buildSectionTitle, _buildInfoRowWithTitle

//  دوال مساعدة بسيطة يمكن وضعها هنا أو في ملف utils
Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
  if (value == null || value.isEmpty || value.toLowerCase() == 'n/a') {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child:
              icon != null
                  ? Icon(
                    icon,
                    size: 16,
                    color: AppColors.textSecondary.withAlpha(
                      (0.8 * 255).round(),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRowWithTitle(String label, String? value, {IconData? icon}) {
  if (value == null || value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary.withAlpha((0.8 * 255).round()),
              )
            else
              const SizedBox(width: 26),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 34.0, top: 2.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionTitle(
  String title, {
  Widget? trailing,
  BuildContext? context,
}) {
  //  أضفت context
  return Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}
//  نهاية الدوال المساعدة

class DesignDetailsSectionWidget extends StatelessWidget {
  final ProjectModel project;
  final bool isUserOwner; //  لتحديد إذا كان المستخدم هو المالك
  final VoidCallback?
  onEditDesignDetails; //  دالة ليتم استدعاؤها عند الضغط على زر التعديل
  final VoidCallback?
  onAddDesignDetails; //  دالة ليتم استدعاؤها عند الضغط على زر إضافة التفاصيل

  const DesignDetailsSectionWidget({
    super.key,
    required this.project,
    required this.isUserOwner,
    this.onEditDesignDetails,
    this.onAddDesignDetails,
  });

  @override
  Widget build(BuildContext context) {
    final ProjectDesignModel? design = project.projectDesign;
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    ); //  افترض أنكِ ستستخدمين هذا

    //  تحديد إذا كان المستخدم يمكنه تعديل/إضافة تفاصيل التصميم بناءً على حالة المشروع
    final bool canUserEditOrAddDesign =
        isUserOwner &&
        (project.status == 'Office Approved - Awaiting Details' ||
            project.status ==
                'Details Submitted - Pending Office Review' || //  قد تسمحين بالتعديل هنا أيضاً
            project.status == 'Payment Proposal Sent' || //  أو هنا
            project.status ==
                'Awaiting User Payment' //  أو هنا
                );
    //  ملاحظة: الشروط أعلاه هي نفسها التي كانت في ProjectDetailsViewScreen
    //  تأكدي من أنها تطابق منطق عملك

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Design Specifications (User Input)',
              context: context, // تمرير context
              trailing:
                  (canUserEditOrAddDesign &&
                          design != null &&
                          onEditDesignDetails != null)
                      ? Tooltip(
                        message: "Edit Design Details",
                        child: InkWell(
                          onTap: onEditDesignDetails,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      )
                      : null,
            ),
            if (design != null) ...[
              _buildInfoRow(
                'Floors:',
                design.floorCount?.toString() ?? 'N/A',
                icon: Icons.stairs_outlined,
              ),
              _buildInfoRow(
                'Bedrooms:',
                design.bedrooms?.toString() ?? 'N/A',
                icon: Icons.bed_outlined,
              ),
              _buildInfoRow(
                'Bathrooms:',
                design.bathrooms?.toString() ?? 'N/A',
                icon: Icons.bathtub_outlined,
              ),
              _buildInfoRow(
                'Kitchens:',
                design.kitchens?.toString() ?? 'N/A',
                icon: Icons.kitchen_outlined,
              ),
              _buildInfoRow(
                'Balconies:',
                design.balconies?.toString() ?? 'N/A',
                icon: Icons.balcony_outlined,
              ),
              _buildInfoRow(
                'Kitchen Type:',
                design.kitchenType ?? 'N/A',
                icon: Icons.restaurant_menu_outlined,
              ),
              _buildInfoRow(
                'Master Has Bathroom:',
                design.masterHasBathroom == true
                    ? 'Yes'
                    : (design.masterHasBathroom == false ? 'No' : 'N/A'),
                icon: Icons.wc_rounded,
              ),
              if (design.specialRooms != null &&
                  design.specialRooms!.isNotEmpty)
                _buildInfoRow(
                  'Special Rooms:',
                  design.specialRooms!.join(', '),
                  icon: Icons.meeting_room_outlined,
                ),
              if (design.directionalRooms != null &&
                  design.directionalRooms!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.compass_calibration_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Directional Rooms:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              (design.directionalRooms!
                                      as List<
                                        dynamic
                                      >) //  افترض أن directionalRooms هي List<Map<String,dynamic>>
                                  .map((e) {
                                    final roomMap = e as Map<String, dynamic>;
                                    return Text(
                                      '• ${roomMap['room']}: ${roomMap['direction']}',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              //  عرض الأوصاف الثلاثة
              if (design.generalDescription != null &&
                  design.generalDescription!.isNotEmpty)
                _buildInfoRowWithTitle(
                  'General Description:',
                  design.generalDescription,
                  icon: Icons.notes_outlined,
                ),
              if (design.interiorDesign != null &&
                  design.interiorDesign!.isNotEmpty)
                _buildInfoRowWithTitle(
                  'Interior Design Notes:',
                  design.interiorDesign,
                  icon: Icons.palette_outlined,
                ),
              if (design.roomDistribution != null &&
                  design.roomDistribution!.isNotEmpty)
                _buildInfoRowWithTitle(
                  'Room Layout/Distribution:',
                  design.roomDistribution,
                  icon: Icons.space_dashboard_outlined,
                ),

              if (design.budgetMin != null || design.budgetMax != null) ...[
                _buildSectionTitle(
                  'User\'s Design Budget Range',
                  context: context,
                ),
                _buildInfoRow(
                  'Min Estimated:',
                  design.budgetMin != null
                      ? currencyFormat.format(design.budgetMin)
                      : 'N/A',
                  icon: Icons.remove_circle_outline_outlined,
                ),
                _buildInfoRow(
                  'Max Estimated:',
                  design.budgetMax != null
                      ? currencyFormat.format(design.budgetMax)
                      : 'N/A',
                  icon: Icons.add_circle_outline_outlined,
                ),
              ],
            ] else if (canUserEditOrAddDesign &&
                onAddDesignDetails !=
                    null) //  إذا كان المستخدم هو المالك ويمكنه الإضافة ولا يوجد تصميم بعد
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        "You haven't submitted design details yet.",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text("Submit Design Details Now"),
                        onPressed: onAddDesignDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Text(
                    "No design details submitted for this project yet.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
