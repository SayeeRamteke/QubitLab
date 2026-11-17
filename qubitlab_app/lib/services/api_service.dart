import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Android emulator reaches your Mac/PC's localhost at 10.0.2.2.
/// Physical phone: use your computer's LAN IP, e.g. http://192.168.1.20:8000
const String kBaseUrl = 'http://10.0.2.2:8000';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$kBaseUrl$path');
    const headers = {'Content-Type': 'application/json'};
    try {
      final http.Response res = method == 'GET'
          ? await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15))
          : await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 15));
      final data = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      throw ApiException(_detail(data) ?? 'Server error (${res.statusCode})');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    } catch (_) {
      throw ApiException(
          'Cannot reach the server at $kBaseUrl. Is uvicorn running?');
    }
  }

  String? _detail(dynamic data) {
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (data is Map && data['detail'] is List && (data['detail'] as List).isNotEmpty) {
      final first = (data['detail'] as List).first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
    }
    return null;
  }

  List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ---- quantum ----
  Future<Map<String, double>> simulate(Map<String, dynamic> circuit) async {
    final d = await _send('POST', '/simulate', body: circuit);
    return (d['results'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
  }

  Future<List<Map<String, dynamic>>> bloch(Map<String, dynamic> circuit) async {
    final d = await _send('POST', '/bloch', body: circuit);
    return _list(d['vectors']);
  }

  // ---- users ----
  Future<Map<String, dynamic>> register(String u, String p) async =>
      Map<String, dynamic>.from(
          await _send('POST', '/users/register', body: {'username': u, 'password': p}) as Map);

  Future<Map<String, dynamic>> login(String u, String p) async =>
      Map<String, dynamic>.from(
          await _send('POST', '/users/login', body: {'username': u, 'password': p}) as Map);

  Future<Map<String, dynamic>> getUser(int id) async =>
      Map<String, dynamic>.from(await _send('GET', '/users/$id') as Map);

  Future<Map<String, dynamic>> progress(int id) async =>
      Map<String, dynamic>.from(await _send('GET', '/progress/$id') as Map);

  // ---- circuits ----
  Future<void> saveCircuit({
    required int userId,
    required String name,
    required int qubits,
    required List<Map<String, dynamic>> gates,
  }) async {
    await _send('POST', '/circuits/save', body: {
      'user_id': userId,
      'name': name,
      'qubits': qubits,
      'circuit_json': gates,
    });
  }

  Future<List<Map<String, dynamic>>> listCircuits(int userId) async =>
      _list(await _send('GET', '/circuits/$userId'));

  // ---- lessons & challenges ----
  Future<void> completeLesson(int lessonId, int userId) async {
    await _send('POST', '/lessons/$lessonId/complete', body: {'user_id': userId});
  }

  Future<List<Map<String, dynamic>>> challenges() async =>
      _list(await _send('GET', '/challenges'));

  Future<Map<String, dynamic>> submitChallenge(
      int challengeId, int userId, Map<String, dynamic> circuit) async {
    final body = {'user_id': userId, ...circuit};
    return Map<String, dynamic>.from(
        await _send('POST', '/challenges/$challengeId/submit', body: body) as Map);
  }
}

final ApiService api = ApiService();
