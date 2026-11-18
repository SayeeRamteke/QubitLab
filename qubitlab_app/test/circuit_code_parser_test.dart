import 'package:flutter_test/flutter_test.dart';
import 'package:qubitlab_app/models/gate.dart';
import 'package:qubitlab_app/providers/circuit_provider.dart';
import 'package:qubitlab_app/utils/circuit_code_parser.dart';

void main() {
  group('CircuitCodeParser', () {
    test('parses empty input with error', () {
      final res = CircuitCodeParser.parse('');
      expect(res.isSuccess, isFalse);
      expect(res.error, contains('empty'));
    });

    test('parses standard Qiskit Bell state code', () {
      const code = '''
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

qc = QuantumCircuit(2)
qc.h(0)
qc.cx(0, 1)
qc.measure_all()
counts = AerSimulator().run(qc).result().get_counts()
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isTrue);
      expect(res.qubits, equals(2));
      expect(res.gates.length, equals(2));

      // First gate: H on q0 at column 0
      expect(res.gates[0].type, equals(GateType.h));
      expect(res.gates[0].target, equals(0));
      expect(res.gates[0].control, isNull);
      expect(res.gates[0].column, equals(0));

      // Second gate: CNOT (cx) from q0 to q1 at column 1
      expect(res.gates[1].type, equals(GateType.cnot));
      expect(res.gates[1].control, equals(0));
      expect(res.gates[1].target, equals(1));
      expect(res.gates[1].column, equals(1));
    });

    test('schedules parallel independent gates in the same column (ASAP)', () {
      const code = '''
qc = QuantumCircuit(3)
qc.h(0)
qc.h(1)
qc.h(2)
qc.cz(0, 1)
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isTrue);
      expect(res.qubits, equals(3));
      expect(res.gates.length, equals(4));

      // h(0), h(1), h(2) should all be placed at column 0
      expect(res.gates[0].column, equals(0));
      expect(res.gates[1].column, equals(0));
      expect(res.gates[2].column, equals(0));

      // cz(0, 1) involves q0 and q1, which were occupied at col 0, so placed at col 1
      expect(res.gates[3].type, equals(GateType.cz));
      expect(res.gates[3].column, equals(1));
    });

    test('supports all single-qubit gates: H, X, Y, Z, S, T', () {
      const code = '''
qc = QuantumCircuit(1)
qc.h(0)
qc.x(0)
qc.y(0)
qc.z(0)
qc.s(0)
qc.t(0)
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isTrue);
      expect(res.gates.map((g) => g.type).toList(), equals([
        GateType.h,
        GateType.x,
        GateType.y,
        GateType.z,
        GateType.s,
        GateType.t,
      ]));
    });

    test('supports OpenQASM format', () {
      const code = '''
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c[2];
h q[0];
cx q[0], q[1];
measure q -> c;
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isTrue);
      expect(res.qubits, equals(2));
      expect(res.gates.length, equals(2));
      expect(res.gates[0].type, equals(GateType.h));
      expect(res.gates[1].type, equals(GateType.cnot));
    });

    test('errors on unsupported gates', () {
      const code = '''
qc = QuantumCircuit(1)
qc.rx(3.14, 0)
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isFalse);
      expect(res.error, contains('not supported'));
    });

    test('errors on out of range qubits', () {
      const code = '''
qc = QuantumCircuit(6)
qc.h(5)
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isFalse);
      expect(res.error, contains('supports up to 5 qubits'));
    });

    test('errors when control and target are the same qubit', () {
      const code = '''
qc = QuantumCircuit(2)
qc.cx(0, 0)
''';
      final res = CircuitCodeParser.parse(code);
      expect(res.isSuccess, isFalse);
      expect(res.error, contains('must be different'));
    });

    test('errors when exceeding grid column limit', () {
      // 13 gates on q0 exceeds 12 columns
      final buffer = StringBuffer('qc = QuantumCircuit(1)\n');
      for (var i = 0; i < 13; i++) {
        buffer.writeln('qc.h(0)');
      }
      final res = CircuitCodeParser.parse(buffer.toString());
      expect(res.isSuccess, isFalse);
      expect(res.error, contains('maximum width of 12 columns'));
    });
  });

  group('CircuitProvider integration with loadFromCode', () {
    test('successfully updates provider state', () {
      final provider = CircuitProvider(qubits: 1);
      expect(provider.qubits, equals(1));
      expect(provider.gates, isEmpty);

      const code = '''
qc = QuantumCircuit(3)
qc.h(0)
qc.cx(0, 1)
qc.cz(1, 2)
''';
      final res = provider.loadFromCode(code);
      expect(res.isSuccess, isTrue);
      expect(provider.qubits, equals(3));
      expect(provider.gates.length, equals(3));
      expect(provider.isEmpty, isFalse);
    });
  });
}
