import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart'; // ✅ لتخزين التوكن على الويب
import '../screens/main_shell_screen.dart';
import '../services/sign/signin_service.dart';
import '../models/Basic/user_model.dart';
import '../services/session.dart';
import 'package:logger/logger.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();
  final storage = FlutterSecureStorage(); // للموبايل
  final webStorage = GetStorage(); // للويب
  final Logger logger = Logger();

  var isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;

      final result = await _authService.signIn(email, password);
      final token = result['token'];
      final userData = result['user'];
      final userType = result['userType'];

      if (token != null && userData != null && userType != null) {
        final user = UserModel.fromJson(userData);

        // استعمل Session مباشرة للتخزين
        await Session.setToken(token);
        await Session.setSession(type: userType, id: user.id);

        logger.i('Login successful: ${user.toJson()}');
        Get.offAll(() => const MainShellScreen());
      } else {
        Get.snackbar('Error', 'Login failed. Invalid credentials.');
        logger.w('Login failed: token/user/userType is null');
      }
    } catch (e) {
      logger.e('Login error: $e');
      Get.snackbar('Error', 'Login failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
