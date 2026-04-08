import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppkd_attendance_app/core/services/auth_services.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';
import 'package:ppkd_attendance_app/presentation/pages/check_in/check_in_page.dart';
import 'package:ppkd_attendance_app/presentation/pages/profile/change_password_page.dart';
import 'package:ppkd_attendance_app/presentation/providers/theme_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthRepository repo = AuthRepository();
  String batch = '';
  String trainingTitle = '';
  String name = '';
  String phone = '';
  bool isLoading = false;
  String email = '';
  int _selectedIndex = 3; // karena profile tab
  String? profilePhotoUrl;
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.access_time_outlined, 'label': 'History'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFD4E600)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _selectedIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);

                  if (i == 0) {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                  if (i == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckInPage(isCheckOut: false),
                      ),
                    );
                  }
                  if (i == 2) {
                    Navigator.pushReplacementNamed(context, '/history');
                  }
                  if (i == 3) {
                    // sudah di profile
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: const Color(0xFF5B7BFF),
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: const TextStyle(
                        color: Color(0xFF5B7BFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7BFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);

    try {
      final res = await repo.getProfile();

      final data = res['data'] ?? res;

      setState(() {
        name = data['name']?.toString() ?? '';
        phone = data['phone']?.toString() ?? data['no_hp']?.toString() ?? '';
        email = data['email']?.toString().trim() ?? '';
        batch = data['batch_ke']?.toString() ?? '';
        trainingTitle = data['training_title']?.toString() ?? '';

        // 🔥 TAMBAH INI
        profilePhotoUrl = data['profile_photo_url'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal load profile')));
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> showLogoutDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, size: 50, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(height: 16),
                Text(
                  "Keluar dari akun?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Kamu harus login kembali untuk mengakses aplikasi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5B8DEF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Color(0xFF5B8DEF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tombol Logout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // tutup dialog dulu
                          await handleLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Keluar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFD4ED26),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Background layers ──────────────────────────────
                Column(
                  children: [
                    // Blue top
                    Container(
                      height: MediaQuery.of(context).size.height * 0.25,
                      color: isDark ? const Color(0xFF1A237E) : const Color(0xFF5B8DEF),
                    ),
                    // Dark navy curve area
                    Expanded(child: Container(color: isDark ? const Color(0xFF121212) : const Color(0xFFD4ED26))),
                  ],
                ),

                // Dark navy wave
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D3250),
                  ),
                ),

                // ── Content ────────────────────────────────────────
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5C518),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child:
                              profilePhotoUrl != null &&
                                  profilePhotoUrl!.isNotEmpty
                              ? Image.network(
                                  profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF2D3250),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF2D3250),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        name.isEmpty ? '-' : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Email
                      Text(
                        email.isEmpty ? '-' : email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: trainingTitle.isEmpty ? '-' : trainingTitle,
                            ),
                            const TextSpan(text: ' - '),
                            TextSpan(
                              text: 'Batch ${batch.isEmpty ? '-' : batch}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Menu card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
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
                            children: [
                              _buildMenuItem(
                                icon: Icons.manage_accounts_outlined,
                                iconColor: const Color(0xFF5B8DEF),
                                title: 'Ubah Profil',
                                onTap: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfilePage(),
                                    ),
                                  );
                                  if (updated == true) loadProfile();
                                },
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.lock_outline,
                                iconColor: const Color(0xFF5B8DEF),
                                title: 'Ubah Kata Sandi',
                                onTap: email.isEmpty
                                    ? () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tunggu data profile selesai dimuat',
                                            ),
                                          ),
                                        );
                                      }
                                    : () async {
                                        setState(() => isLoading = true);

                                        final res = await repo.forgotPassword(
                                          email,
                                        );

                                        setState(() => isLoading = false);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              res['message'] ??
                                                  'Terjadi kesalahan',
                                            ),
                                          ),
                                        );

                                        if (res['message'] ==
                                            "OTP berhasil dikirim ke email") {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ChangePasswordPage(
                                                    email: email,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                              _buildDivider(),

                              // 🌙 Dark Mode Toggle
                              ListTile(
                                leading: Icon(
                                  isDark ? Icons.dark_mode : Icons.light_mode,
                                  color: const Color(0xFF5B8DEF),
                                ),
                                title: Text(
                                  'Mode Gelap',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                trailing: Switch(
                                  value: themeProvider.isDarkMode,
                                  onChanged: (_) => themeProvider.toggle(),
                                  activeTrackColor: const Color(0xFF5B8DEF),
                                ),
                              ),
                              _buildDivider(),

                              _buildMenuItem(
                                icon: Icons.logout,
                                iconColor: Colors.red,
                                title: 'Keluar',
                                titleColor: Colors.red,
                                onTap: showLogoutDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor);

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
    );
  }
}

// Wave clipper buat efek melengkung
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
