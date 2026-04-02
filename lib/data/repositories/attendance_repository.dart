import '../../core/services/api_services.dart';

class AttendanceRepository {
  Future<Map<String, dynamic>> checkIn(double lat, double lng) async {
    return await ApiService.post("/absen/check-in", {
      "latitude": lat,
      "longitude": lng,
    });
  }

  Future<Map<String, dynamic>> checkOut(double lat, double lng) async {
    return await ApiService.post("/absen/check-out", {
      "latitude": lat,
      "longitude": lng,
    });
  }

  Future<Map<String, dynamic>> getHistory() async {
    return await ApiService.get("/absen/history");
  }

  Future<Map<String, dynamic>> deleteAbsen(int id) async {
    return await ApiService.delete("/absen/$id");
  }
}
