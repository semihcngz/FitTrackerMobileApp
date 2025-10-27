import 'package:flutter/foundation.dart';

enum AuthStatus { loading, authed, guest }

class AuthService extends ChangeNotifier {
  AuthStatus status = AuthStatus.loading;
  Map<String, dynamic>? me;

  bool get isAuthed => status == AuthStatus.authed;

  Future<void> bootstrap() async {
    // uygulama ilk açıldığında direkt guest moda geçsin
    await Future.delayed(const Duration(milliseconds: 500));
    status = AuthStatus.guest;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    // sahte login: hiçbir kontrol yok, direkt başarılı say
    await Future.delayed(const Duration(milliseconds: 300));
    me = {'name': 'Semih', 'email': email};
    status = AuthStatus.authed;
    notifyListeners();
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    // sahte kayıt: sadece login'e yönlendiriyor
    await Future.delayed(const Duration(milliseconds: 300));
    return login(email, password);
  }

  Future<void> logout() async {
    me = null;
    status = AuthStatus.guest;
    notifyListeners();
  }
}
