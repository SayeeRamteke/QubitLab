import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  int? userId;
  String username = '';
  int xp = 0;
  int streak = 0;
  Set<int> completedLessons = {};
  Set<int> completedChallenges = {};
  bool booting = true;

  bool get loggedIn => userId != null;

  void _apply(Map<String, dynamic> u) {
    userId = u['id'] as int;
    username = u['username'] as String;
    xp = u['xp'] as int;
    streak = u['streak_days'] as int;
  }

  /// Called once at app start: restores the saved session if the server is reachable.
  Future<void> boot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id != null) {
        _apply(await api.getUser(id));
        await refreshProgress();
      }
    } catch (_) {
      userId = null;
    }
    booting = false;
    notifyListeners();
  }

  Future<void> login(String u, String p) async {
    _apply(await api.login(u, p));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId!);
    await refreshProgress();
    notifyListeners();
  }

  Future<void> register(String u, String p) async {
    await api.register(u, p);
    await login(u, p);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    userId = null;
    completedLessons = {};
    completedChallenges = {};
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (userId == null) return;
    _apply(await api.getUser(userId!));
    notifyListeners();
  }

  Future<void> refreshProgress() async {
    if (userId == null) return;
    final p = await api.progress(userId!);
    completedLessons = (p['completed_lessons'] as List).cast<int>().toSet();
    completedChallenges = (p['completed_challenges'] as List).cast<int>().toSet();
    notifyListeners();
  }
}
