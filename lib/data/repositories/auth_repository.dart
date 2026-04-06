import 'package:ppkd_attendance_app/core/services/api_services.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiService.post("/login", {
      "email": email,
      "password": password,
    });
  }

  Future<Map<String, dynamic>> getBatches() async {
    return await ApiService.get("/batches");
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    int batchId,
    int trainingId,
    String jenisKelamin,
  ) async {
    final body = {
      "name": name,
      "email": email,
      "password": password,
      "jenis_kelamin": jenisKelamin,
      "batch_id": batchId,
      "training_id": trainingId,
    };

    print("REGISTER BODY: $body");

    return await ApiService.post("/register", body);
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get("/profile");
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    return await ApiService.put("/profile", {"name": name, "email": email});
  }

  Future<Map<String, dynamic>> absen(double lat, double lng) async {
    return await ApiService.post("/attendance", {
      "latitude": lat,
      "longitude": lng,
    });
  }
}
