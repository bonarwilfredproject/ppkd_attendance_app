import 'package:flutter/material.dart';
import 'package:ppkd_attendance_app/core/services/auth_services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> handleLogout(BuildContext context) async {
    await AuthService.logout();

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 20),

            const Text("User Login", style: TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => handleLogout(context),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
