// widgets/project_sections/office_payment_proposal_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/Basic/project_model.dart';
import '../../themes/app_colors.dart';

//  نحتاج لدوال _buildInfoRow و _buildSectionTitle هنا أيضاً
//  (يفضل وضعها في ملف utils مشترك)
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

class OfficePaymentProposalWidget extends StatelessWidget {
  final ProjectModel project;
  final TextEditingController paymentAmountController;
  final TextEditingController paymentNotesController;
  final bool isProposingPayment; //  حالة التحميل
  final VoidCallback onProposePayment;

  const OfficePaymentProposalWidget({
    super.key,
    required this.project,
    required this.paymentAmountController,
    required this.paymentNotesController,
    required this.isProposingPayment,
    required this.onProposePayment,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar_JO',
      symbol: 'د.أ',
      name: 'JOD',
    );
    const sizedBoxTiny = SizedBox(height: 8);

    //  تحديد إذا كان المكتب يمكنه اقتراح سعر بناءً على حالة المشروع
    final bool canProposePayment =
        project.status == 'Details Submitted - Pending Office Review' ||
        project.status == 'Awaiting Payment Proposal by Office';
    //  أو حالة أخرى مثل (لم يتم اقتراح سعر بعد ولم يتم الدفع)
    // && (project.proposedPaymentAmount == null || project.proposedPaymentAmount == 0)
    // && project.paymentStatus?.toLowerCase() != 'paid';

    //  تحديد إذا كان السعر قد تم اقتراحه بالفعل
    final bool paymentAlreadyProposed =
        project.proposedPaymentAmount != null &&
        project.proposedPaymentAmount! > 0 &&
        (project.status == 'Payment Proposal Sent' ||
            project.status == 'Awaiting User Payment' ||
            project.status == 'In Progress' ||
            project.status == 'Completed');

    if (!canProposePayment && !paymentAlreadyProposed) {
      //  لا تعرض شيئاً إذا لم يكن الوقت مناسباً لاقتراح السعر أو إذا لم يتم اقتراحه بعد
      return const SizedBox.shrink();
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
            _buildSectionTitle(
              'Payment Proposal (For Office)',
              context: context,
            ),
            if (paymentAlreadyProposed) ...[
              _buildInfoRow(
                'Proposed Amount:',
                currencyFormat.format(project.proposedPaymentAmount!),
                icon: Icons.price_check_rounded,
              ),
              if (project.paymentNotes != null &&
                  project.paymentNotes!.isNotEmpty)
                _buildInfoRow(
                  'Office Notes:',
                  project.paymentNotes,
                  icon: Icons.notes_rounded,
                ),
              _buildInfoRow(
                'Payment Status:',
                project.paymentStatus ?? 'N/A',
                icon: Icons.credit_card_outlined,
              ),
              if (project.paymentStatus?.toLowerCase().contains('pending') ??
                  true)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Payment proposal has been sent to the user.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                )
              else if (project.paymentStatus?.toLowerCase() == 'paid')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Payment received. Project is active.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ] else if (canProposePayment) ...[
              //  إذا كان يمكن اقتراح السعر ولم يتم اقتراحه بعد
              TextFormField(
                controller: paymentAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Propose Payment Amount (JOD)',
                  prefixText: '${currencyFormat.currencySymbol} ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final pValue = double.tryParse(value);
                  if (pValue == null || pValue <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              sizedBoxTiny,
              TextFormField(
                controller: paymentNotesController,
                decoration: InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                maxLines: 2,
              ),
              sizedBoxTiny,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      isProposingPayment
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.send_and_archive_outlined,
                            size: 18,
                          ),
                  label: Text(
                    isProposingPayment
                        ? 'Sending...'
                        : 'Send Payment Proposal to User',
                    style: const TextStyle(fontSize: 14),
                  ),
                  onPressed: isProposingPayment ? null : onProposePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
