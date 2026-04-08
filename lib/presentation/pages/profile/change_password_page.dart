import 'package:flutter/material.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;

  const ChangePasswordPage({super.key, required this.email});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final repo = AuthRepository();

  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final otpFocus = FocusNode();
  final passFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool isLoading = false;
  bool obscurePass = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    /// AUTO FOCUS OTP pas halaman kebuka
    Future.delayed(const Duration(milliseconds: 300), () {
      otpFocus.requestFocus();
    });
  }

  Future<void> handleSubmit() async {
    if (otpController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
      return;
    }

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password tidak sama")));
      return;
    }

    setState(() => isLoading = true);

    final res = await repo.resetPassword(
      widget.email,
      otpController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));

    if (res['message'] == "Password berhasil diperbarui") {
      Navigator.pop(context);
    }
  }

  Widget buildInput({
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      style: TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5B8DEF)),
        ),
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: toggle,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFD4ED26),
      body: Stack(
        children: [
          // ── Background layers (sama seperti EditProfilePage) ──
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                color: isDark ? const Color(0xFF1A237E) : const Color(0xFF5B8DEF),
              ),
              Expanded(child: Container(color: isDark ? const Color(0xFF121212) : const Color(0xFFD4ED26))),
            ],
          ),

          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D3250),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 8),

                // Icon kunci sebagai pengganti avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5C518),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 52,
                    color: Color(0xFF2D3250),
                  ),
                ),

                const SizedBox(height: 32),

                // Form card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildInput(
                            hint: "Masukkan OTP",
                            controller: otpController,
                            focusNode: otpFocus,
                            nextFocus: passFocus,
                          ),
                          const SizedBox(height: 16),
                          buildInput(
                            hint: "Password baru",
                            controller: passwordController,
                            focusNode: passFocus,
                            nextFocus: confirmFocus,
                            obscure: obscurePass,
                            toggle: () =>
                                setState(() => obscurePass = !obscurePass),
                          ),
                          const SizedBox(height: 16),
                          buildInput(
                            hint: "Konfirmasi password",
                            controller: confirmController,
                            focusNode: confirmFocus,
                            obscure: obscureConfirm,
                            toggle: () => setState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B8DEF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Simpan",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.95,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
