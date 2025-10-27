import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E0F12),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9AA0FF),
        secondary: Color(0xFF9AA0FF),
        surface: Color(0xFF14161A),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF14161A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF191C20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0E0F12), elevation: 0),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..bootstrap()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HealthFit',
        theme: dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isAuthed ? const HomeShell() : const LoginScreen();
  }
}
