import 'package:intl/intl.dart';
import '../../core/services/api_services.dart';

class IzinRepository {
  Future<Map<String, dynamic>> createIzin(DateTime date, String alasan) async {
    return await ApiService.post("/izin", {
      "date": DateFormat('yyyy-MM-dd').format(date),
      "alasan_izin": alasan,
    });
  }
}
