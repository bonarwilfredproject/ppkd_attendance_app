import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveRememberMe(String email, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', remember);
    await prefs.setString('remember_email', email);
  }

  static Future<Map<String, dynamic>> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "remember": prefs.getBool('remember_me') ?? false,
      "email": prefs.getString('remember_email') ?? '',
    };
  }

  static Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('remember_email');
  }
}
