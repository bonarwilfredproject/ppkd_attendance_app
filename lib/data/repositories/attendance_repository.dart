import 'package:intl/intl.dart';

import '../../core/services/api_services.dart';

class AttendanceRepository {
  Future<Map<String, dynamic>> checkIn(
    double lat,
    double lng,
    String address,
  ) async {
    final now = DateTime.now();

    return await ApiService.post("/absen/check-in", {
      "attendance_date": DateFormat('yyyy-MM-dd').format(now),
      "check_in": DateFormat('HH:mm').format(now),
      "check_in_lat": lat,
      "check_in_lng": lng,
      "check_in_address": address,
      "status": "masuk",
    });
  }

  Future<Map<String, dynamic>> deleteAbsen({
    required int id,
    required String name,
    required String email,
    required String password,
  }) async {
    return await ApiService.delete(
      "/absen/$id",
      body: {"name": name, "email": email, "password": password},
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    return await ApiService.get("/absen/stats");
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return await ApiService.get(
      "/absen/today",
      queryParameters: {"attendance_date": today},
    );
  }

  Future<Map<String, dynamic>> checkOut(
    double lat,
    double lng,
    String address,
  ) async {
    final now = DateTime.now();

    return await ApiService.post("/absen/check-out", {
      "attendance_date": DateFormat('yyyy-MM-dd').format(now),
      "check_out": DateFormat('HH:mm').format(now),
      "check_out_lat": lat,
      "check_out_lng": lng,
      "check_out_location": "$lat, $lng", // 🔥 WAJIB
      "check_out_address": address,
    });
  }

  Future<Map<String, dynamic>> getHistory() async {
    return await ApiService.get("/absen/history");
  }
}
