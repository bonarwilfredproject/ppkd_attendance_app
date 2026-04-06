import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';

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

  // ── data ─────────────────────────────────────────────────
  Future<void> loadHistory() async {
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
  }

  // ── helpers ───────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      return DateFormat('EEE, dd MMMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
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
                onPressed: () => Navigator.pop(context),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
              return Padding(
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
                        Text(
                          '$checkIn - $checkOut',
                          style: TextStyle(
                            fontSize: 14,
                            color: late ? Colors.red : Colors.black87,
                            fontWeight: late
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
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
                    if (checkOutAddress != '-' && checkOutAddress != null) ...[
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
