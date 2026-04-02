import 'package:flutter/material.dart';
import 'package:ppkd_attendance_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:ppkd_attendance_app/presentation/pages/profile/profile_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/pages/auth/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
