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

class SimulationResult {
  final Map<String, double> probabilities;
  final List<Map<String, dynamic>> blochVectors;

  const SimulationResult({
    required this.probabilities,
    required this.blochVectors,
  });
}

class MathStep {
  final int stepIndex;
  final String title;
  final String description;
  final String gateLabel;
  final String operatorLatex;
  final String inputStateLatex;
  final String calculationLatex;
  final String outputStateLatex;
  final String diracLatex;
  final Map<String, double> probabilities;

  const MathStep({
    required this.stepIndex,
    required this.title,
    required this.description,
    required this.gateLabel,
    required this.operatorLatex,
    required this.inputStateLatex,
    required this.calculationLatex,
    required this.outputStateLatex,
    required this.diracLatex,
    required this.probabilities,
  });

  factory MathStep.fromJson(Map<String, dynamic> json) {
    return MathStep(
      stepIndex: json['step_index'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      gateLabel: json['gate_label'] as String,
      operatorLatex: json['operator_latex'] as String,
      inputStateLatex: json['input_state_latex'] as String,
      calculationLatex: json['calculation_latex'] as String,
      outputStateLatex: json['output_state_latex'] as String,
      diracLatex: json['dirac_latex'] as String,
      probabilities: (json['probabilities'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
    );
  }
}

class MathBreakdown {
  final int qubits;
  final int dimension;
  final String inputStateLatex;
  final List<MathStep> steps;

  const MathBreakdown({
    required this.qubits,
    required this.dimension,
    required this.inputStateLatex,
    required this.steps,
  });

  factory MathBreakdown.fromJson(Map<String, dynamic> json) {
    return MathBreakdown(
      qubits: json['qubits'] as int,
      dimension: json['dimension'] as int,
      inputStateLatex: json['input_state_latex'] as String,
      steps: (json['steps'] as List)
          .map((s) => MathStep.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
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

  Future<SimulationResult> simulateDetailed(Map<String, dynamic> circuit) async {
    final d = await _send('POST', '/simulate', body: circuit);
    final probs = (d['results'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    List<Map<String, dynamic>> vectors;
    if (d['bloch_vectors'] is List) {
      vectors = _list(d['bloch_vectors']);
    } else {
      vectors = await bloch(circuit);
    }
    return SimulationResult(probabilities: probs, blochVectors: vectors);
  }

  Future<List<Map<String, dynamic>>> bloch(Map<String, dynamic> circuit) async {
    final d = await _send('POST', '/bloch', body: circuit);
    return _list(d['vectors']);
  }

  Future<MathBreakdown> getMathBreakdown(Map<String, dynamic> circuit) async {
    final d = await _send('POST', '/math_breakdown', body: circuit);
    return MathBreakdown.fromJson(Map<String, dynamic>.from(d as Map));
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
