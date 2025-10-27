import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(); final pass = TextEditingController(); String? err; bool loading=false;
  @override Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 8),
        if (err!=null) Text(err!, style: const TextStyle(color: Colors.red)),
        FilledButton(
          onPressed: () async { setState(()=>loading=true); final e = await auth.login(email.text.trim(), pass.text.trim()); setState((){err=e; loading=false;}); },
          child: loading ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Sign In'),
        ),
        TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>const RegisterScreen())), child: const Text('Sign Up')),
      ]),
    );
  }
}
