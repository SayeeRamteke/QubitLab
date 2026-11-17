import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SavedCircuitsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> circuits = [];
  bool loading = false;
  String? error;

  Future<void> load(int userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      circuits = await api.listCircuits(userId);
    } on ApiException catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }
}
