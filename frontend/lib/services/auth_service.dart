// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'secure_store.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  final _api = ApiClient.instance;
  final _store = SecureStore();
  
  AuthStatus _status = AuthStatus.loading;
  Map<String, dynamic>? _user;

  AuthStatus get status => _status;
  bool get isAuthed => _status == AuthStatus.authenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> bootstrap() async {
    try {
      final user = await me();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.postJson('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    final token = res['token'] as String?;
    if (token != null) await _store.setToken(token);
    _user = res['user'] as Map<String, dynamic>?;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return {
      'user': res['user'],
      'token': token,
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    // tokeni kaydet
    final token = res['token'] as String?;
    if (token != null) await _store.setToken(token);
    _user = res['user'] as Map<String, dynamic>?;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return {
      'user': res['user'],
      'token': token,
    };
  }

  Future<Map<String, dynamic>?> me() async {
    final res = await _api.getJson('/api/auth/me');
    return res['user'] as Map<String, dynamic>?;
  }

  Future<void> logout() async {
    await _store.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
