import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _s = FlutterSecureStorage();
  static const _k = 'access_token';
  static Future<void> setToken(String token) => _s.write(key: _k, value: token);
  static Future<String?> getToken() => _s.read(key: _k);
  static Future<void> clear() => _s.delete(key: _k);
}
