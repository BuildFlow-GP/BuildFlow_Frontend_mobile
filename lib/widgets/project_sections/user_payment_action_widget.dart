// widgets/project_sections/user_payment_action_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/Basic/project_model.dart';
import '../../themes/app_colors.dart';

//  الدوال المساعدة (يفضل utils)
Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
  /* ... نفس الدالة ... */
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

Widget _buildSectionTitle(
  String title, {
  Widget? trailing,
  BuildContext? context,
}) {
  /* ... نفس الدالة ... */
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

class UserPaymentActionWidget extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onMakePayment; //  دالة للانتقال لصفحة الدفع

  const UserPaymentActionWidget({
    super.key,
    required this.project,
    required this.onMakePayment,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    );

    final bool canMakePayment =
        (project.status == 'Payment Proposal Sent' ||
            project.status == 'Awaiting User Payment') &&
        project.proposedPaymentAmount != null &&
        project.proposedPaymentAmount! > 0;
    final bool isPaid =
        project.paymentStatus?.toLowerCase() == 'paid' ||
        [
          'In Progress',
          'Completed',
        ].contains(project.status); //  إذا بدأ العمل أو اكتمل، فهو مدفوع

    if (!canMakePayment && !isPaid) {
      //  لا تعرض شيئاً إذا لم يكن هناك دفعة مطلوبة أو إذا لم يتم الدفع بعد ولم يحن وقت الدفع
      return const SizedBox.shrink();
    }
    if (canMakePayment && isPaid) {
      // حالة غريبة، إذا كان يمكن الدفع ومدفوع! (لا يجب أن تحدث)
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Payment Information', context: context),
              Center(
                child: Chip(
                  label: Text(
                    "Payment Processed & Confirmed",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green.shade600,
                  avatar: Icon(Icons.price_check_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Payment Information', context: context),
            _buildInfoRow(
              'Amount Due (from Office):',
              project.proposedPaymentAmount != null
                  ? currencyFormat.format(project.proposedPaymentAmount!)
                  : 'N/A',
              icon: Icons.monetization_on_outlined,
            ),
            if (project.paymentNotes != null &&
                project.paymentNotes!.isNotEmpty)
              _buildInfoRow(
                'Office Notes on Payment:',
                project.paymentNotes,
                icon: Icons.sticky_note_2_outlined,
              ),
            _buildInfoRow(
              'Payment Status:',
              project.paymentStatus ?? 'Pending',
              icon: Icons.credit_score_outlined,
            ),
            const SizedBox(height: 12),
            if (canMakePayment && !isPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 15),
                  ),
                  onPressed: onMakePayment, //  استدعاء الـ callback
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            else if (isPaid) //  إذا تم الدفع
              Center(
                child: Chip(
                  label: Text(
                    "Payment Confirmed",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green.shade600,
                  avatar: Icon(Icons.price_check_rounded, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
