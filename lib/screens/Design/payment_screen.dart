// screens/Design/payment_screen.dart
// import 'dart:convert'; // غير مستخدم مباشرة هنا
import 'package:buildflow_frontend/services/create/payment_service.dart'; // ✅
import 'package:buildflow_frontend/themes/app_colors.dart';
// import 'package:buildflow_frontend/utils/constants.dart'; // غير مستخدم مباشرة هنا
import 'package:flutter/material.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:intl/intl.dart'; //  لـ currencyFormat
import 'package:logger/logger.dart';
// import '../services/session.dart'; //  غير مستخدم مباشرة هنا، السيرفس تستخدمه

final Logger logger = Logger();

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final int projectId;

  const PaymentScreen({
    super.key,
    required this.totalAmount, //  تأكدي أن هذا يستقبل القيمة الصحيحة
    required this.projectId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey =
      GlobalKey<
        FormState
      >(); //  يبقى للتحقق من صحة حقول Braintree DropIn إذا كانت مدمجة

  //  الـ Controllers لحقول البطاقة ليست ضرورية إذا استخدمنا BraintreeDropIn UI بالكامل
  // final _cardNumberController = TextEditingController();
  // final _expiryDateController = TextEditingController();
  // final _cvvController = TextEditingController();

  bool _isLoading = false; //  عام لعملية الدفع
  // bool _areFieldsFilled = false; //  لن نحتاجه إذا استخدمنا DropIn UI ونعتمد على زر Braintree

  String? _clientToken;
  bool _isFetchingClientToken = true;
  final PaymentService _paymentService = PaymentService();

  //  لـ currencyFormat
  final currencyFormat = NumberFormat.currency(
    locale: 'ar_JO',
    symbol: 'د.أ',
    name: 'JOD',
  );

  @override
  void initState() {
    super.initState();
    _fetchClientToken();
    //  لا حاجة للـ listeners إذا لم نستخدم الـ controllers
  }

  @override
  void dispose() {
    // _cardNumberController.dispose();
    // _expiryDateController.dispose();
    // _cvvController.dispose();
    super.dispose();
  }

  Future<void> _fetchClientToken() async {
    if (!mounted) return;
    setState(() => _isFetchingClientToken = true);
    try {
      _clientToken = await _paymentService.getClientToken();
      logger.i(
        "Braintree Client Token fetched for PaymentScreen: ${_clientToken != null}",
      );
      if (mounted) setState(() => _isFetchingClientToken = false);
    } catch (e) {
      logger.e("Error fetching client token in PaymentScreen: $e");
      if (mounted) {
        setState(() => _isFetchingClientToken = false);
        _showPaymentResultDialog(
          context,
          title: 'Payment Initialization Error',
          content: "Could not initialize payment service: ${e.toString()}",
          isSuccess: false,
        );
      }
    }
  }

  void _processPaymentWithBraintree() async {
    //  إذا كنتِ ستستخدمين حقول الإدخال الخاصة بكِ (Card Tokenization):
    // if (!_formKey.currentState!.validate()) {
    //   _showPaymentResultDialog(context, title: 'Validation Failed', content: 'Please check your card details.', isSuccess: false);
    //   return;
    // }

    if (_clientToken == null) {
      _showPaymentResultDialog(
        context,
        title: 'Payment Error',
        content: 'Payment service is not ready. Please try again.',
        isSuccess: false,
      );
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final request = BraintreeDropInRequest(
      clientToken: _clientToken!,
      collectDeviceData: true,
      cardEnabled: true,
      // ✅ تم تعليق هذا الجزء مؤقتاً لتجنب الخطأ
      // threeDeeSecureRequest: BraintreeThreeDeeSecureRequest(
      //   amount: widget.totalAmount.toStringAsFixed(2),
      // ),
    );

    try {
      final BraintreeDropInResult? braintreeResult =
          await BraintreeDropIn.start(request);

      // ✅✅✅ تعديل طريقة التحقق من الخطأ ✅✅✅
      if (braintreeResult != null) {
        logger.i(
          "Braintree Nonce received: ${braintreeResult.paymentMethodNonce.nonce}",
        );

        final Map<String, dynamic> checkoutResult = await _paymentService
            .processCheckout(
              paymentMethodNonce: braintreeResult.paymentMethodNonce.nonce,
              amount: widget.totalAmount,
              projectId: widget.projectId,
            );

        if (!mounted) return;
        if (checkoutResult['success'] == true) {
          _showPaymentResultDialog(
            context,
            title: 'Payment Successful',
            content:
                checkoutResult['message'] ??
                'Thank you! Your payment of ${currencyFormat.format(widget.totalAmount)} was successful. Transaction ID: ${checkoutResult['transactionId']}',
            isSuccess: true,
            onOkPressed: () {
              Navigator.of(context).pop(true);
            },
          );
        } else {
          _showPaymentResultDialog(
            context,
            title: 'Payment Failed',
            content:
                checkoutResult['message'] ??
                'An error occurred during payment processing.',
            isSuccess: false,
          );
        }
      } else if (braintreeResult == null) {
        // User cancelled the Braintree Drop-In
        logger.i("Braintree Drop-In cancelled by user.");
        // Optionally show a message or do nothing
        // _showPaymentResultDialog(context, title: 'Payment Cancelled', content: 'Payment process was cancelled.', isSuccess: false);
      } else {
        // If there is no nonce and the user did not cancel, this means an error from Braintree SDK
        logger.e(
          "Braintree Drop-In failed or returned no nonce. Potentially SDK error. Result: ${braintreeResult.toString()}",
        );
        if (mounted) {
          _showPaymentResultDialog(
            context,
            title: 'Payment System Error',
            content:
                'A problem occurred with the payment system. Please try again or contact support.',
            isSuccess: false,
          );
        }
      }
    } catch (e, s) {
      logger.e(
        "Error during Braintree Drop-In or checkout",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        _showPaymentResultDialog(
          context,
          title: 'Payment Error',
          content: 'An unexpected error occurred: ${e.toString()}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentResultDialog(
    BuildContext context, {
    required String title,
    required String content,
    required bool isSuccess,
    VoidCallback? onOkPressed,
  }) {
    // ... (نفس الكود)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onOkPressed != null) {
                    onOkPressed();
                  }
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // دوال التحقق من البطاقة (تبقى موجودة إذا أردتِ استخدامها لاحقاً مع Card Tokenization)
  // String? _validateExpiryDate(String? value) { /* ... */ }
  // String? _validateCardNumber(String? value) { /* ... */ }
  // String? _validateCVV(String? value) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileLayout = screenWidth < 700;
    final bool useMaxWidth = screenWidth > 1000;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: null,
      body: Column(
        children: [
          Container(
            /* AppBar المخصص - يبقى كما هو */
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 28,
                      ),
                      color: AppColors.accent,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        "Secure Payment",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: useMaxWidth ? 600 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobileLayout ? 16.0 : 24.0),
                  child: Card(
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: AppColors.card,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(isMobileLayout ? 16.0 : 20.0),
                      child:
                          _isFetchingClientToken
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : (_clientToken == null
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Could not initialize payment service.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.refresh),
                                          label: const Text(
                                            "Retry Initialization",
                                          ),
                                          onPressed: _fetchClientToken,
                                        ),
                                      ],
                                    ),
                                  )
                                  : Form(
                                    //  إذا استخدمنا DropIn، الـ Form هنا قد لا يكون ضرورياً للحقول
                                    key:
                                        _formKey, //  يبقى مفيداً إذا كان هناك حقول أخرى
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildPaymentSummary(isMobileLayout),
                                        const SizedBox(height: 24),
                                        //  إذا اعتمدنا على Braintree DropIn UI، لا نحتاج لهذا القسم
                                        // _buildCardDetailsSection(isMobileLayout),
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20.0,
                                              horizontal: 16.0,
                                            ),
                                            child: Text(
                                              "You will be prompted to enter your card details securely via Braintree.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppColors.textSecondary
                                                    .withOpacity(0.8),
                                                fontStyle: FontStyle.italic,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 28,
                                        ), // تعديل المسافة
                                        _buildPayButton(),
                                        const SizedBox(
                                          height: 20,
                                        ), // تعديل المسافة
                                        _buildSecureGatewayNotice(),
                                      ],
                                    ),
                                  )),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(bool isMobileLayout) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(isMobileLayout ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.accent,
                size: 26,
              ),
              title: Text(
                'Service Fee for Project ID: ${widget.projectId}',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
              ),
              trailing: Text(
                currencyFormat.format(widget.totalAmount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  ✅✅✅  هذا القسم أصبح غير ضروري إذا استخدمنا Braintree Drop-In UI ✅✅✅
  // Widget _buildCardDetailsSection(bool isMobileLayout) { /* ... */ }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              (_clientToken != null && !_isFetchingClientToken)
                  ? AppColors.accent
                  : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        onPressed:
            (_clientToken != null && !_isFetchingClientToken && !_isLoading)
                ? _processPaymentWithBraintree
                : null,
        icon:
            _isLoading
                ? Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 8),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                : const Icon(Icons.payment_rounded, size: 20), //  أيقونة مختلفة
        label: Text(
          _isLoading
              ? 'Processing...'
              : 'Pay ${currencyFormat.format(widget.totalAmount)} Securely',
        ),
      ),
    );
  }

  Widget _buildSecureGatewayNotice() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_rounded,
              color: Colors.green.shade700,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              "Payments processed securely by Braintree",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  _buildTextFormField أصبح غير ضروري إذا استخدمنا Drop-In UI
  // Widget _buildTextFormField(...) { ... }
}
