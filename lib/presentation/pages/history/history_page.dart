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

    final password = await showDialog<String>(
      context: context,
      builder: (_) {
        bool isObscure = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
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

                    const Text(
                      "Konfirmasi Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: passwordController,
                      obscureText: isObscure,
                      decoration: InputDecoration(
                        hintText: "Masukkan password",
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),

                        // 👁️ ICON TOGGLE
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
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
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Batal",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, passwordController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
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

    if (password == null || password.isEmpty) return false;

    try {
      final res = await repo.deleteAbsen(
        id: id,
        name: name,
        email: email,
        password: password,
      );

      final message = res['message'] ?? '';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      return message == "Data absen berhasil dihapus";
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      return false;
    }
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                ? const Center(child: Text('Belum ada data'))
                : _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF5B7BFF),
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // section title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: const [
                Icon(Icons.history, color: Colors.black87, size: 22),
                SizedBox(width: 8),
                Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
                direction: DismissDirection.endToStart, // swipe ke kiri
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

                            const Text(
                              "Hapus Absen",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "Yakin mau hapus data ini?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
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
                                    child: const Text(
                                      "Batal",
                                      style: TextStyle(color: Colors.black),
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
                    data.removeWhere(
                      (e) => e['id'].toString() == item['id'].toString(),
                    );
                  });
                  // 🔥 refresh dari API (BEST PRACTICE)
                  await loadHistory();

                  return true;
                },

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(dateStr),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$checkIn - $checkOut',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: late ? Colors.red : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildHistoryBadge(status, late),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 📍 LOCATION
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Masuk: $checkInAddress',
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // kalau ada check out → tampilkan juga
                      if (checkOutAddress != '-' &&
                          checkOutAddress != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.outbond,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Keluar: $checkOutAddress',
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 12,
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

    return Container(
      decoration: const BoxDecoration(color: Color(0xFFD4E600)),
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
