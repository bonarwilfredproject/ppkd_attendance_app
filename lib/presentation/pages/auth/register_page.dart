import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  int batchId = 1;
  int trainingId = 1;
  String jenisKelamin = "L"; // L / P
  bool isLoading = false;

  final repo = AuthRepository();

  Future<void> handleRegister() async {
    setState(() => isLoading = true);
    if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }
    final res = await repo.register(
      nameC.text,
      emailC.text,
      passC.text,
      batchId,
      trainingId,
      jenisKelamin,
    );

    setState(() => isLoading = false);

    if (res['errors'] != null) {
      // ambil pesan error pertama
      final errorMsg = res['message'] ?? "Register gagal";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register berhasil")));

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: emailC,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            DropdownButtonFormField<String>(
              value: jenisKelamin,
              items: const [
                DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                DropdownMenuItem(value: "P", child: Text("Perempuan")),
              ],
              onChanged: (value) {
                setState(() {
                  jenisKelamin = value!;
                });
              },
              decoration: const InputDecoration(labelText: "Jenis Kelamin"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : handleRegister,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
