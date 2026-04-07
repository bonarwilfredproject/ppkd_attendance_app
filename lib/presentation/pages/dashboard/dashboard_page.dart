import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ppkd_attendance_app/core/services/location_service.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';

import 'package:ppkd_attendance_app/presentation/pages/check_in/check_in_page.dart';
import 'package:ppkd_attendance_app/presentation/pages/izin/izin_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── state ────────────────────────────────────────────────
  LatLng? currentLatLng;
  bool isLoading = false;
  String? userName;
  String? userNip;
  String? userRole;
  final AttendanceRepository repo = AttendanceRepository();
  List historyData = [];
  int totalAbsen = 0;
  int absenHariIni = 0;
  GoogleMapController? mapController;
  StreamSubscription<Position>? positionStream;
  Timer? _clockTimer;
  String _liveTime = DateFormat('hh:mm a').format(DateTime.now());
  String _liveDate = DateFormat('EEE, dd MMMM yyyy').format(DateTime.now());
  int _selectedIndex = 0;
  String? userBatch;
  String? userTraining;
  int totalMasuk = 0;
  int totalIzin = 0;
  bool sudahAbsenHariIni = false;
  String? checkInToday;
  String? checkOutToday;
  bool get isCheckedIn => checkInToday != null;
  bool get isCheckedOut => checkOutToday != null;
  String? todayStatus; // NEW
  String? profilePhotoUrl;
  // ── init ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    getLocation();
    startTrackingLocation();
    loadProfile();
    loadAttendance();
    loadStats(); // ✅ tambah ini
    loadToday(); // ✅ tambah ini
    _startClock();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      setState(() {
        _liveTime = DateFormat('hh:mm a').format(now);
        _liveDate = DateFormat('EEE, dd MMMM yyyy').format(now);
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  // ── data loaders ─────────────────────────────────────────
  Future<void> loadProfile() async {
    final authRepo = AuthRepository();
    final res = await authRepo.getProfile();
    setState(() {
      final data = res['data'];

      userName = data['name'];
      userNip = data['nip']?.toString() ?? '';
      userRole = data['role'] ?? '';

      userBatch = data['batch_ke']?.toString() ?? '';
      userTraining = data['training_title']?.toString() ?? '';
      profilePhotoUrl = data['profile_photo_url'];
    });
  }

  Future<void> loadStats() async {
    try {
      final res = await repo.getStats(); // bikin di repository
      final data = res['data'];

      setState(() {
        totalAbsen = data['total_absen'] ?? 0;
        totalMasuk = data['total_masuk'] ?? 0;
        totalIzin = data['total_izin'] ?? 0;
        sudahAbsenHariIni = data['sudah_absen_hari_ini'] ?? false;
      });
    } catch (e) {
      debugPrint('Error loadStats: $e');
    }
  }

  Future<void> loadToday() async {
    try {
      final res = await repo.getTodayAttendance();
      final data = res['data'];

      setState(() {
        checkInToday = data['check_in_time'];
        checkOutToday = data['check_out_time'];
        todayStatus = data['status']; // 🔥 penting
      });
    } catch (e) {
      debugPrint('Error loadToday: $e');
    }
  }

  Widget _buildStatusBadge() {
    String text = 'Belum Absen';
    Color color = Colors.grey;

    if (todayStatus == 'izin') {
      text = 'IZIN';
      color = Colors.orange;
    } else if (isCheckedIn) {
      final late = _isLate(checkInToday);
      if (late) {
        text = 'TERLAMBAT';
        color = Colors.red;
      } else {
        text = 'HADIR';
        color = Colors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHistoryBadge(Map item) {
    final status = item['status'];
    final late = _isLate(item['check_in_time']);

    String text = 'HADIR';
    Color color = Colors.green;

    if (status == 'izin') {
      text = 'IZIN';
      color = Colors.orange;
    } else if (late) {
      text = 'TELAT';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> loadAttendance() async {
    final res = await repo.getHistory();
    final data = res['data'] as List;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int todayCount = 0;
    for (var item in data) {
      if (item['date'] == today) todayCount++;
    }
    setState(() {
      historyData = data;
      totalAbsen = data.length;
      absenHariIni = todayCount;
    });
  }

  // ── location ─────────────────────────────────────────────
  void startTrackingLocation() {
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) {
          final newLatLng = LatLng(pos.latitude, pos.longitude);
          setState(() => currentLatLng = newLatLng);
          mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
        });
  }

  Future<void> getLocation() async {
    setState(() => isLoading = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() => currentLatLng = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => isLoading = false);
  }

  // ── helpers ───────────────────────────────────────────────
  String _formatHistoryDate(String raw) {
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [_buildAttendanceCard(), _buildHistorySection()],
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B7BFF), Color(0xFF7FA1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            children: [
              // 🔥 Avatar modern
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFCA65), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                      ? Image.network(
                          profilePhotoUrl!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 32),
                ),
              ),

              const SizedBox(width: 14),

              // 🔥 User info (lebih rapi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${userName ?? 'User'} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      userTraining ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Batch ${userBatch ?? '-'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 Logout button (clean)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── attendance card ───────────────────────────────────────
  Widget _buildAttendanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 36, 16, 0),
      transform: Matrix4.translationValues(0, -16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live clock section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              children: [
                const Text(
                  'Live Attendance',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _liveTime,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B7BFF),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _liveDate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Office hours
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: const [
                Text(
                  'Office Hours',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                SizedBox(height: 6),
                Text(
                  '08:00 AM -  05:00 PM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  sudahAbsenHariIni
                      ? 'Sudah absen hari ini'
                      : 'Belum absen hari ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: sudahAbsenHariIni ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total Absen: $totalAbsen',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          if (checkInToday != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Masuk: $checkInToday  |  Keluar: ${checkOutToday ?? '--'}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          _buildStatusBadge(),
          const SizedBox(height: 10),
          // Check in / Check out buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading || isCheckedOut || todayStatus == 'izin'
                    ? null
                    : () async {
                        final isCheckOutMode = isCheckedIn;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CheckInPage(isCheckOut: isCheckOutMode),
                          ),
                        );

                        if (result == true) {
                          loadToday(); // refresh status hari ini
                          loadStats(); // refresh statistik
                          loadAttendance();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: todayStatus == 'izin'
                      ? Colors.grey
                      : isCheckedOut
                      ? Colors.grey
                      : isCheckedIn
                      ? Colors.orange
                      : const Color(0xFF5B7BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Text(
                  todayStatus == 'izin'
                      ? 'Sedang Izin'
                      : isCheckedOut
                      ? 'Sudah Check Out'
                      : isCheckedIn
                      ? 'Check Out'
                      : 'Check In',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IzinPage()),
                  );

                  if (result == true) {
                    loadToday();
                    loadStats();
                  }
                },
                icon: const Icon(Icons.event_busy),
                label: const Text("Ajukan Izin"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5B7BFF),
                  side: const BorderSide(color: Color(0xFF5B7BFF)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── history section ───────────────────────────────────────
  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          // header row
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

          // list
          if (historyData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada data')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyData.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final item = historyData[index];
                final dateStr = item['attendance_date'] ?? item['date'] ?? '';
                final checkIn = item['check_in_time'] ?? '-';
                final checkOut = item['check_out_time'] ?? '-';
                final late = _isLate(item['check_in_time']);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatHistoryDate(dateStr),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$checkIn - $checkOut',
                              style: TextStyle(
                                fontSize: 13,
                                color: late ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHistoryBadge(item),
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
      decoration: BoxDecoration(
        color: const Color(0xFFD4E600),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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

                  if (i == 0) {
                    // sudah di dashboard
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
                    Navigator.pushNamed(context, '/history');
                  }

                  if (i == 3) {
                    Navigator.pushNamed(context, '/profile');
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
}
