import 'package:ppkd_attendance_app/core/services/api_services.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiService.post("/login", {
      "email": email,
      "password": password,
    });
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    int batchId,
    int trainingId,
    String jenisKelamin,
  ) async {
    return await ApiService.post("/register", {
      "name": name,
      "email": email,
      "password": password,
      "batch_id": batchId,
      "training_id": trainingId,
      "jenis_kelamin": jenisKelamin,
    });
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get("/profile");
  }

  Future<Map<String, dynamic>> absen(double lat, double lng) async {
    return await ApiService.post("/attendance", {
      "latitude": lat,
      "longitude": lng,
    });
  }
}
