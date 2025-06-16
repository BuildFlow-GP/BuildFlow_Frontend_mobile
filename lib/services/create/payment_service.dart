// services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; //  إذا كنتِ تستخدمينه

import '../session.dart';
import '../../utils/constants.dart'; //  لـ Constants.baseUrl

final Logger logger = Logger(); //  إذا كنتِ ستستخدمينه

class PaymentService {
  final String _baseUrl = Constants.baseUrl;

  Future<String?> getClientToken() async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    logger.i("Fetching Braintree Client Token...");
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/payment/client-token',
      ), // تأكدي أن المسار صحيح (قد يكون /api/payment/client-token)
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    logger.i("Get Client Token Response Status: ${response.statusCode}");
    if (response.statusCode != 200) {
      logger.e("Get Client Token Response Body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('clientToken')) {
        return data['clientToken'] as String?;
      } else {
        throw Exception('Client token not found in response.');
      }
    } else {
      String errorMessage = 'Failed to fetch client token.';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = data['error'] ?? data['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> processCheckout({
    //  سترجع Map لنتيجة الـ checkout
    required String paymentMethodNonce,
    required double amount,
    required int projectId,
  }) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final Map<String, dynamic> requestBody = {
      'paymentMethodNonce': paymentMethodNonce,
      'amount': amount,
      'projectId': projectId,
    };

    logger.i(
      "Processing checkout for project $projectId: ${jsonEncode(requestBody)}",
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/payment/checkout'), //  تأكدي أن المسار صحيح
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    logger.i("Process Checkout Response Status: ${response.statusCode}");
    logger.i("Process Checkout Response Body: ${response.body}");

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && responseData['success'] == true) {
      //  النجاح
      return responseData; //  { success: true, message: '...', transactionId: '...', project: { ... } }
    } else {
      //  الفشل
      String errorMessage =
          responseData['message'] ??
          responseData['error'] ??
          'Payment processing failed.';
      //  إذا كان الـ backend يرجع قائمة أخطاء Braintree
      // if (responseData.containsKey('errors') && responseData['errors'] is List && (responseData['errors'] as List).isNotEmpty) {
      //    errorMessage += "\nDetails: ${(responseData['errors'] as List).map((e) => e.toString()).join(', ')}";
      // }
      throw Exception(errorMessage);
    }
  }
}
