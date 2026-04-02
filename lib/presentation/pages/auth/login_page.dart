import 'package:flutter/material.dart';
import 'package:ppkd_attendance_app/core/services/auth_services.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  bool isLoading = false;

  final AuthRepository repo = AuthRepository();

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
    });

    final res = await repo.login(emailC.text.trim(), passC.text.trim());

    setState(() {
      isLoading = false;
    });

    final token = res['token'] ?? res['data']?['token'];

    if (token != null) {
      await AuthService.saveToken(token);

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      final message = res['message'] ?? "Login gagal";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailC,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("Belum punya akun? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
