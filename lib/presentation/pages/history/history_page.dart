import 'package:flutter/material.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final repo = AttendanceRepository();
  List data = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final res = await repo.getHistory();
    setState(() {
      data = res['data'] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Absen")),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];

          return ListTile(
            title: Text(item['date'] ?? '-'),
            subtitle: Text(
              "Masuk: ${item['check_in']} | Pulang: ${item['check_out']}",
            ),
          );
        },
      ),
    );
  }
}
