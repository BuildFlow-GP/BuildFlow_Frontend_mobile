import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  static final GetStorage _webStorage = GetStorage();
  static final FlutterSecureStorage _mobileStorage =
      const FlutterSecureStorage();

  static Future<void> setSession({
    required String type,
    required int id,
  }) async {
    if (kIsWeb) {
      await _webStorage.write('userType', type);
      await _webStorage.write('userId', id);
    } else {
      await _mobileStorage.write(key: 'userType', value: type);
      await _mobileStorage.write(key: 'userId', value: id.toString());
    }
  }

  static Future<String?> getUserType() async {
    if (kIsWeb) {
      return _webStorage.read('userType');
    } else {
      return await _mobileStorage.read(key: 'userType');
    }
  }

  static Future<int?> getUserId() async {
    if (kIsWeb) {
      final val = _webStorage.read('userId');
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      return null;
    } else {
      final val = await _mobileStorage.read(key: 'userId');
      if (val == null) return null;
      return int.tryParse(val);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      return _webStorage.read('jwt_token');
    } else {
      return await _mobileStorage.read(key: 'jwt_token');
    }
  }

  static Future<void> setToken(String token) async {
    if (kIsWeb) {
      await _webStorage.write('jwt_token', token);
    } else {
      await _mobileStorage.write(key: 'jwt_token', value: token);
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      await _webStorage.erase();
    } else {
      await _mobileStorage.deleteAll();
    }
  }
}
