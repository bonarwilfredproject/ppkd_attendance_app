import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';
import 'package:ppkd_attendance_app/presentation/pages/check_in/check_in_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final repo = AttendanceRepository();
  List data = [];
  bool isLoading = true;
  int _selectedIndex = 2;
  Map<String, dynamic>? user;
  // ── data ─────────────────────────────────────────────────
  Future<void> loadHistory() async {
    setState(() => isLoading = true); // 🔥 tambahin ini

    try {
      final res = await repo.getHistory();
      setState(() {
        data = res['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
    loadProfile(); // 🔥 tambahin ini
  }

  // ── helpers ───────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      return DateFormat('EEE, dd MMMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> loadProfile() async {
    try {
      final authRepo = AuthRepository();
      final res = await authRepo.getProfile();

      setState(() {
        user = res['data'];
      });
    } catch (e) {
      print("ERROR PROFILE: $e");
    }
  }

  Future<bool> handleDeleteAbsen(int id) async {
    final name = user?['name'] ?? '';
    final email = user?['email'] ?? '';

    final passwordController = TextEditingController();

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        bool isObscure = true;
        String? errorText;
        bool isDeleting = false;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF5B7BFF),
                      size: 40,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Konfirmasi Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(dialogContext).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Masukkan password akun Anda untuk\nmenghapus data absensi ini",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: isObscure,
                      enabled: !isDeleting,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(dialogContext).colorScheme.onSurface,
                      ),
                      onChanged: (_) {
                        // Clear error when user starts typing
                        if (errorText != null) {
                          setStateDialog(() {
                            errorText = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                          fontSize: 13,
                        ),

                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? Colors.red
                                : isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? Colors.red
                                : const Color(0xFF5B8DEF),
                          ),
                        ),

                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),

                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),

                        errorText: errorText,
                        errorStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: isDeleting
                              ? null
                              : () {
                                  setStateDialog(() {
                                    isObscure = !isObscure;
                                  });
                                },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting
                                ? null
                                : () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(
                                color: isDeleting
                                    ? Colors.grey
                                    : Theme.of(
                                        dialogContext,
                                      ).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    // Validate empty password
                                    final password = passwordController.text
                                        .trim();
                                    if (password.isEmpty) {
                                      setStateDialog(() {
                                        errorText = "Password wajib diisi";
                                      });
                                      return;
                                    }

                                    // Start loading
                                    setStateDialog(() {
                                      isDeleting = true;
                                      errorText = null;
                                    });

                                    try {
                                      // Step 1: Verify password via login API
                                      final authRepo = AuthRepository();
                                      final loginRes = await authRepo.login(
                                        email,
                                        password,
                                      );

                                      // Check if login was successful (password is correct)
                                      if (loginRes['data'] == null ||
                                          loginRes['data']['token'] == null) {
                                        // Password is wrong
                                        setStateDialog(() {
                                          isDeleting = false;
                                          errorText =
                                              "Password salah, silakan coba lagi";
                                        });
                                        return;
                                      }

                                      // Step 2: Password verified, proceed with delete
                                      final res = await repo.deleteAbsen(
                                        id: id,
                                        name: name,
                                        email: email,
                                        password: password,
                                      );

                                      final message = res['message'] ?? '';

                                      if (message.toLowerCase().contains(
                                        "berhasil dihapus",
                                      )) {
                                        // Success — close dialog
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext, true);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(message),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        // Delete API error (data not found, etc.)
                                        setStateDialog(() {
                                          isDeleting = false;
                                          errorText = message;
                                        });
                                      }
                                    } catch (e) {
                                      setStateDialog(() {
                                        isDeleting = false;
                                        errorText =
                                            "Terjadi kesalahan, coba lagi";
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isDeleting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Lanjut",
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
      },
    );

    return success == true;
  }

  Widget _buildHistoryBadge(String? status, bool late) {
    String text = '';
    Color color = Colors.grey;

    if (status == 'izin') {
      text = 'IZIN';
      color = Colors.orange;
    } else if (late) {
      text = 'TELAT';
      color = Colors.red;
    } else {
      text = 'HADIR';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  bool _isLate(String? timeStr) {
    if (timeStr == null) return false;
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return h > 8 || (h == 8 && m > 0);
    } catch (_) {
      return false;
    }
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                ? const Center(child: Text('Belum ada data'))
                : SingleChildScrollView(child: _buildList()),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── header ────────────────────────────────────────────────
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1A237E) : const Color(0xFF5B7BFF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/dashboard',
                    arguments: 0, // index home
                  );
                },
              ),
              const Expanded(
                child: Text(
                  'Attendance History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── list ──────────────────────────────────────────────────
  Widget _buildList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = data[index];
              final dateStr = item['attendance_date'] ?? item['date'] ?? '';
              final checkIn = item['check_in_time'] ?? '-';
              final checkOut = item['check_out_time'] ?? '-';
              final late = _isLate(item['check_in_time']);
              final checkInAddress = item['check_in_address'] ?? '-';
              final checkOutAddress = item['check_out_address'] ?? '-';
              final status = item['status'];

              return Dismissible(
                key: Key(item['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF5B7BFF),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Hapus Absen",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Yakin mau hapus data ini?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Batal",
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5B7BFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Hapus",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (confirm != true) return false;
                  final success = await handleDeleteAbsen(item['id']);
                  if (!success) return false;

                  setState(() {
                    data.removeAt(index);
                  });
                  return false;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date and Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5B7BFF,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  size: 16,
                                  color: Color(0xFF5B7BFF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatDate(dateStr),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          _buildHistoryBadge(status, late),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Times & Location Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Check In Area ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.login,
                                          size: 14,
                                          color: late ? Colors.red : Colors.green,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Waktu Masuk',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      checkIn,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: late
                                            ? Colors.red
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            checkInAddress,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ── Divider ──
                              VerticalDivider(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                thickness: 1,
                                width: 24,
                              ),

                              // ── Check Out Area ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.logout,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Waktu Pulang',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      checkOut,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (checkOutAddress != '-' &&
                                        checkOutAddress != '') ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              checkOutAddress,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── bottom nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.access_time_outlined, 'label': 'History'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFD4E600),
      ),
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
                  if (i == 0)
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  if (i == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckInPage(isCheckOut: false),
                      ),
                    );
                  }
                  if (i == 3) Navigator.pushNamed(context, '/profile');
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
}
