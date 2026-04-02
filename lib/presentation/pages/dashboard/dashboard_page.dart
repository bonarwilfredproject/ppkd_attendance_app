import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ppkd_attendance_app/core/services/location_service.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';
import 'package:ppkd_attendance_app/data/repositories/auth_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  LatLng? currentLatLng;
  bool isLoading = false;
  String? userName;
  final AttendanceRepository repo = AttendanceRepository();
  int totalAbsen = 0;
  int absenHariIni = 0;
  String today = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
  Future<void> loadProfile() async {
    final authRepo = AuthRepository();
    final res = await authRepo.getProfile();
    setState(() {
      userName = res['data']['name'];
    });
  }

  Future<void> loadAttendance() async {
    final res = await repo.getHistory();
    final data = res['data'];

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int todayCount = 0;

    for (var item in data) {
      if (item['date'] == today) {
        todayCount++;
      }
    }

    setState(() {
      totalAbsen = data.length;
      absenHariIni = todayCount;
    });
  }

  Future<void> getLocation() async {
    setState(() => isLoading = true);

    try {
      final pos = await LocationService.getCurrentLocation();

      setState(() {
        currentLatLng = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  Future<void> handleCheckIn() async {
    if (currentLatLng == null) return;

    setState(() => isLoading = true);

    final res = await repo.checkIn(
      currentLatLng!.latitude,
      currentLatLng!.longitude,
    );

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? "Absen masuk berhasil")),
    );
  }

  Future<void> handleCheckOut() async {
    if (currentLatLng == null) return;

    setState(() => isLoading = true);

    final res = await repo.checkOut(
      currentLatLng!.latitude,
      currentLatLng!.longitude,
    );

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? "Absen pulang berhasil")),
    );
  }

  @override
  void initState() {
    super.initState();
    getLocation();
    loadProfile(); // 🔥 ini penting
    loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentLatLng == null
          ? const Center(child: Text("Lokasi tidak ditemukan"))
          : Column(
              children: [
                // 🔥 HEADER
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, ${userName ?? 'User'} 👋",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(today),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "$totalAbsen",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Total Absen"),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "$absenHariIni",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Hari Ini"),
                      ],
                    ),
                  ],
                ),
                // 🗺️ MAP
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: currentLatLng!,
                      zoom: 17,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("me"),
                        position: currentLatLng!,
                      ),
                    },
                  ),
                ),

                // 🔥 BUTTON ABSEN
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleCheckIn,
                          child: const Text("Absen Masuk"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleCheckOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Absen Pulang"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
