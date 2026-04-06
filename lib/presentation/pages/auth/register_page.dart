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
  List batches = [];
  List trainings = [];

  int? batchId;
  int? trainingId;
  String jenisKelamin = "L";
  bool isLoading = false;
  bool _obscurePassword = true;

  final repo = AuthRepository();

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    try {
      final res = await repo.getBatches();
      setState(() {
        batches = res['data'];
      });
    } catch (e) {
      print("ERROR GET BATCHES: $e");
    }
  }

  void handleBatchChange(int? id) {
    final selectedBatch = batches.firstWhere((b) => b['id'] == id);
    setState(() {
      batchId = id;
      trainings = selectedBatch['trainings'];
      trainingId = null;
    });
  }

  Future<void> handleRegister() async {
    if (nameC.text.isEmpty || emailC.text.isEmpty || passC.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }
    if (batchId == null || trainingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih batch & pelatihan")));
      return;
    }
    setState(() => isLoading = true);

    try {
      final res = await repo.register(
        nameC.text.trim(),
        emailC.text.trim(),
        passC.text.trim(),
        batchId!,
        trainingId!,
        jenisKelamin,
      );

      print("REGISTER RESPONSE: $res");

      if (res['data'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Register berhasil")));
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final message = res['message'] ?? "Register gagal";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  // ── helpers ──────────────────────────────────────────────
  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF4A4A4A),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  InputDecoration _fieldDecoration({Widget? suffixIcon}) => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFEEEEEE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF5B7BFF), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    suffixIcon: suffixIcon,
  );

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E600), // yellow bottom accent
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── dark header ──
          Container(
            color: const Color(0xFF3D4560),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Register to your account',
                      style: TextStyle(
                        color: Color(0xFFB0B8C8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── white card (scrollable) ──
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama
                    _buildLabel('Nama'),
                    TextField(
                      controller: nameC,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildLabel('Email'),
                    TextField(
                      controller: emailC,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      decoration: _fieldDecoration(),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    _buildLabel('Password'),
                    TextField(
                      controller: passC,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      decoration: _fieldDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 22,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Jenis Kelamin
                    _buildLabel('Jenis Kelamin'),
                    DropdownButtonFormField<String>(
                      value: jenisKelamin,
                      items: const [
                        DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                        DropdownMenuItem(value: "P", child: Text("Perempuan")),
                      ],
                      onChanged: (value) =>
                          setState(() => jenisKelamin = value!),
                      decoration: _fieldDecoration(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 20),

                    // Pilih Batch
                    _buildLabel('Pilih Batch'),
                    DropdownButtonFormField<int>(
                      value: batchId,
                      items: batches.map<DropdownMenuItem<int>>((batch) {
                        return DropdownMenuItem<int>(
                          value: batch['id'],
                          child: Text("Batch ${batch['batch_ke']}"),
                        );
                      }).toList(),
                      onChanged: handleBatchChange,
                      decoration: _fieldDecoration(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      hint: const Text(
                        'Pilih Batch',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pilih Pelatihan
                    _buildLabel('Pilih Pelatihan'),
                    DropdownButtonFormField<int>(
                      value: trainingId,
                      items: trainings.map<DropdownMenuItem<int>>((training) {
                        return DropdownMenuItem<int>(
                          value: training['id'],
                          child: Text(training['title']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => trainingId = value),
                      decoration: _fieldDecoration(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      hint: const Text(
                        'Pilih Pelatihan',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B7BFF),
                          disabledBackgroundColor: const Color(
                            0xFF5B7BFF,
                          ).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Already have account
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: RichText(
                          text: const TextSpan(
                            text: "Sudah punya akun? ",
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color(0xFF222222),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
