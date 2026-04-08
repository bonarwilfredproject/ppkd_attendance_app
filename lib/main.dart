import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppkd_attendance_app/presentation/providers/theme_provider.dart';
import 'package:ppkd_attendance_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:ppkd_attendance_app/presentation/pages/history/history_page.dart';
import 'package:ppkd_attendance_app/presentation/pages/profile/profile_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/pages/auth/register_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/history': (context) => const HistoryPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
