import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState() => _RegisterScreenState(); }
class _RegisterScreenState extends State<RegisterScreen> {
  final name=TextEditingController(), email=TextEditingController(), pass=TextEditingController(); String? err; bool loading=false;
  @override Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 8),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 8),
        if (err!=null) Text(err!, style: const TextStyle(color: Colors.red)),
        FilledButton(
          onPressed: () async { setState(()=>loading=true); try { await auth.register(name: name.text.trim(), email: email.text.trim(), password: pass.text.trim()); setState((){err=null; loading=false;}); if(mounted) Navigator.pop(context); } catch(e) { setState((){err=e.toString(); loading=false;}); } },
          child: loading ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Create Account'),
        ),
      ]),
    );
  }
}
