// lib/services/secure_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _kTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setToken(String token) async {
    await _storage.write(key: _kTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _kTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _kTokenKey);
  }
}
