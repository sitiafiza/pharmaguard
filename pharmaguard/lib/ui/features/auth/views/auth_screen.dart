import 'package:flutter/material.dart';
import '../../shell/views/main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _obs = true;
  @override
  Widget build(BuildContext context) {
    return FloatingPhoneMockup(
      maxWidth: 480,
      child: Scaffold(
        backgroundColor: Colors.white, 
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF0D9488)), 
                const SizedBox(height: 24), 
                const Text('PharmaGuard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 48), 
                TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))), 
                const SizedBox(height: 20), 
                TextField(obscureText: _obs, decoration: InputDecoration(labelText: 'Sandi', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_obs ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obs = !_obs)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))), 
                const SizedBox(height: 32), 
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), 
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper())), 
                    child: const Text('Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  )
                )
              ]
            )
          )
        )
      )
    );
  }
}