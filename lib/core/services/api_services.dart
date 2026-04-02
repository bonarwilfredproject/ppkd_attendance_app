import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://appabsensi.mobileprojp.com/api";

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token", // 🔥 INI PENTING
      },
      body: jsonEncode(body),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    return jsonDecode(res.body);
  }
}
