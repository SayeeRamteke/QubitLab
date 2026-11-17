import 'package:flutter/foundation.dart';
import '../models/gate.dart';

/// Holds the circuit being built. The Lab uses one global instance;
/// lessons and Arena challenges create their own local instance.
class CircuitProvider extends ChangeNotifier {
  static const int columns = 12;
  static const int maxQubits = 5;

  CircuitProvider({int qubits = 2}) : _qubits = qubits.clamp(1, maxQubits);

  int _qubits;
  String _name = 'Untitled circuit';
  final List<PlacedGate> _gates = [];
  int _idSeq = 0;

  int get qubits => _qubits;
  String get name => _name;
  List<PlacedGate> get gates => List.unmodifiable(_gates);
  bool get isEmpty => _gates.isEmpty;

  void setName(String n) {
    _name = n; // no notify: only read when saving
  }

  PlacedGate? gateAt(int qubit, int column, {String? ignoreId}) {
    for (final g in _gates) {
      if (g.id == ignoreId) continue;
      if (g.column == column && g.involves(qubit)) return g;
    }
    return null;
  }

  int _targetFor(GateType t, int q) {
    if (!t.isTwoQubit) return q;
    return q + 1 < _qubits ? q + 1 : q - 1;
  }

  bool canPlace(GateType type, int qubit, int column, {String? ignoreId}) {
    if (qubit < 0 || qubit >= _qubits || column < 0 || column >= columns) return false;
    if (type.isTwoQubit && _qubits < 2) return false;
    if (gateAt(qubit, column, ignoreId: ignoreId) != null) return false;
    if (type.isTwoQubit &&
        gateAt(_targetFor(type, qubit), column, ignoreId: ignoreId) != null) {
      return false;
    }
    return true;
  }

  bool place(GateType type, int qubit, int column, {String? moveId}) {
    if (!canPlace(type, qubit, column, ignoreId: moveId)) return false;
    if (moveId != null) _gates.removeWhere((g) => g.id == moveId);
    _gates.add(PlacedGate(
      id: 'g${_idSeq++}',
      type: type,
      column: column,
      target: _targetFor(type, qubit),
      control: type.isTwoQubit ? qubit : null,
    ));
    notifyListeners();
    return true;
  }

  void removeGate(String id) {
    _gates.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  void swapControlTarget(String id) {
    final i = _gates.indexWhere((g) => g.id == id);
    if (i == -1 || _gates[i].control == null) return;
    _gates[i] = _gates[i].swapped();
    notifyListeners();
  }

  void addQubit() {
    if (_qubits >= maxQubits) return;
    _qubits++;
    notifyListeners();
  }

  void removeQubit() {
    if (_qubits <= 1) return;
    _qubits--;
    _gates.removeWhere((g) => g.involves(_qubits));
    notifyListeners();
  }

  void clear() {
    _gates.clear();
    notifyListeners();
  }

  /// Replace the whole circuit with a saved one.
  void loadFrom(String name, int qubits, List<dynamic> savedGates) {
    _gates.clear();
    _name = name;
    _qubits = qubits.clamp(1, maxQubits);
    for (var i = 0; i < savedGates.length; i++) {
      final m = Map<String, dynamic>.from(savedGates[i] as Map);
      final type = GateType.values.firstWhere((t) => t.apiName == m['type']);
      _gates.add(PlacedGate(
        id: 'g${_idSeq++}',
        type: type,
        column: (m['column'] as int?) ?? i,
        target: m['target'] as int,
        control: m['control'] as int?,
      ));
    }
    notifyListeners();
  }

  List<PlacedGate> get _sorted =>
      [..._gates]..sort((a, b) => a.column.compareTo(b.column));

  /// Exactly the payload FastAPI POST /simulate expects.
  Map<String, dynamic> toJson() => {
        'qubits': _qubits,
        'gates': _sorted.map((g) => g.toJson()).toList(),
      };

  /// Same gates plus "column", so a saved circuit reloads exactly as drawn.
  List<Map<String, dynamic>> toStorageGates() =>
      _sorted.map((g) => {...g.toJson(), 'column': g.column}).toList();

  /// One-way translator: visual circuit -> Qiskit Python code.
  String toQiskitCode() {
    final b = StringBuffer()
      ..writeln('from qiskit import QuantumCircuit')
      ..writeln('from qiskit_aer import AerSimulator')
      ..writeln()
      ..writeln('qc = QuantumCircuit($_qubits)');
    for (final g in _sorted) {
      b.writeln(switch (g.type) {
        GateType.h => 'qc.h(${g.target})',
        GateType.x => 'qc.x(${g.target})',
        GateType.y => 'qc.y(${g.target})',
        GateType.z => 'qc.z(${g.target})',
        GateType.s => 'qc.s(${g.target})',
        GateType.t => 'qc.t(${g.target})',
        GateType.cnot => 'qc.cx(${g.control}, ${g.target})',
        GateType.cz => 'qc.cz(${g.control}, ${g.target})',
      });
    }
    b
      ..writeln('qc.measure_all()')
      ..writeln()
      ..writeln('counts = AerSimulator().run(qc, shots=1024).result().get_counts()')
      ..writeln('print(counts)');
    return b.toString();
  }
}
