import 'dart:math' as math;
import '../models/gate.dart';
import '../providers/circuit_provider.dart';

class ParsedCircuitResult {
  final int qubits;
  final List<PlacedGate> gates;
  final String? error;

  bool get isSuccess => error == null;

  const ParsedCircuitResult.success({
    required this.qubits,
    required this.gates,
  }) : error = null;

  const ParsedCircuitResult.failure(this.error)
      : qubits = 0,
        gates = const [];
}

class CircuitCodeParser {
  static const int maxColumns = CircuitProvider.columns; // 12
  static const int maxQubits = CircuitProvider.maxQubits; // 5

  /// Parses Qiskit Python code or OpenQASM into qubits and placed gates.
  static ParsedCircuitResult parse(String code) {
    if (code.trim().isEmpty) {
      return const ParsedCircuitResult.failure('Code is empty. Please enter some quantum circuit code.');
    }

    final lines = code.split('\n');
    int? explicitQubits;
    final parsedOperations = <_RawOp>[];

    // Regular expressions for various syntax forms:
    // 1. QuantumCircuit declaration: QuantumCircuit(2) or QuantumCircuit(2, 2)
    final qcDeclRegex = RegExp(r'QuantumCircuit\s*\(\s*(\d+)');
    // OpenQASM qreg: qreg q[2];
    final qregRegex = RegExp(r'qreg\s+\w+\s*\[\s*(\d+)\s*\]', caseSensitive: false);

    // 2. Gate operations:
    // Qiskit method calls: qc.h(0), circuit.cx(0, 1), h(0), etc.
    final methodCallRegex = RegExp(r'(?:[a-zA-Z_]\w*\.)?([a-zA-Z]+)\s*\(([^)]*)\)');

    // OpenQASM single gate: h q[0]; or h 0;
    final qasmSingleRegex = RegExp(r'^([a-zA-Z]+)\s+(?:[a-zA-Z_]\w*\[)?(\d+)\]?\s*;?$');
    // OpenQASM two-qubit gate: cx q[0], q[1]; or cx 0, 1;
    final qasmTwoRegex = RegExp(r'^([a-zA-Z]+)\s+(?:[a-zA-Z_]\w*\[)?(\d+)\]?\s*,\s*(?:[a-zA-Z_]\w*\[)?(\d+)\]?\s*;?$');

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      var line = lines[lineIdx].trim();
      final lineNum = lineIdx + 1;

      // Strip trailing comment
      final commentIdx = line.indexOf('#');
      if (commentIdx != -1) {
        line = line.substring(0, commentIdx).trim();
      }
      final slashCommentIdx = line.indexOf('//');
      if (slashCommentIdx != -1) {
        line = line.substring(0, slashCommentIdx).trim();
      }

      if (line.isEmpty) continue;

      // Skip imports, simulator boilerplate, print, comments
      if (line.startsWith('import ') ||
          line.startsWith('from ') ||
          line.startsWith('print(') ||
          line.startsWith('OPENQASM') ||
          line.startsWith('include ') ||
          line.contains('AerSimulator') ||
          line.contains('.result()') ||
          line.contains('.get_counts()')) {
        continue;
      }

      // Check QuantumCircuit declaration
      final qcMatch = qcDeclRegex.firstMatch(line);
      if (qcMatch != null) {
        final q = int.tryParse(qcMatch.group(1)!);
        if (q != null) explicitQubits = q;
        continue;
      }

      final qregMatch = qregRegex.firstMatch(line);
      if (qregMatch != null) {
        final q = int.tryParse(qregMatch.group(1)!);
        if (q != null) explicitQubits = q;
        continue;
      }

      // Skip measurement instructions
      if (line.contains('.measure') || line.startsWith('measure ') || line.startsWith('creg ')) {
        continue;
      }

      // Try method call: qc.gate(...)
      final methodMatch = methodCallRegex.firstMatch(line);
      if (methodMatch != null) {
        final gateName = methodMatch.group(1)!.toLowerCase();
        final rawArgs = methodMatch.group(2)!.trim();

        final parsedOp = _parseGateArgs(gateName, rawArgs, lineNum);
        if (parsedOp.error != null) {
          return ParsedCircuitResult.failure(parsedOp.error);
        }
        if (parsedOp.op != null) {
          parsedOperations.add(parsedOp.op!);
        }
        continue;
      }

      // Try OpenQASM two-qubit: cx q[0], q[1];
      final qasmTwoMatch = qasmTwoRegex.firstMatch(line);
      if (qasmTwoMatch != null) {
        final gateName = qasmTwoMatch.group(1)!.toLowerCase();
        final c = int.tryParse(qasmTwoMatch.group(2)!);
        final t = int.tryParse(qasmTwoMatch.group(3)!);
        if (c == null || t == null) {
          return ParsedCircuitResult.failure('Invalid qubit arguments at line $lineNum: "$line"');
        }
        final parsedOp = _resolveTwoQubitGate(gateName, c, t, lineNum);
        if (parsedOp.error != null) return ParsedCircuitResult.failure(parsedOp.error);
        if (parsedOp.op != null) parsedOperations.add(parsedOp.op!);
        continue;
      }

      // Try OpenQASM single-qubit: h q[0];
      final qasmSingleMatch = qasmSingleRegex.firstMatch(line);
      if (qasmSingleMatch != null) {
        final gateName = qasmSingleMatch.group(1)!.toLowerCase();
        final q = int.tryParse(qasmSingleMatch.group(2)!);
        if (q == null) {
          return ParsedCircuitResult.failure('Invalid qubit argument at line $lineNum: "$line"');
        }
        final parsedOp = _resolveSingleQubitGate(gateName, q, lineNum);
        if (parsedOp.error != null) return ParsedCircuitResult.failure(parsedOp.error);
        if (parsedOp.op != null) parsedOperations.add(parsedOp.op!);
        continue;
      }

      // If line looks like variable assignment or code not recognized as a gate
      if (line.contains('=') && !line.contains('QuantumCircuit')) {
        // e.g. shots = 1024 or counts = ...
        continue;
      }

      return ParsedCircuitResult.failure('Line $lineNum: Unrecognized instruction "$line"');
    }

    // Determine number of qubits
    int maxReferencedQubit = -1;
    for (final op in parsedOperations) {
      if (op.target > maxReferencedQubit) maxReferencedQubit = op.target;
      if (op.control != null && op.control! > maxReferencedQubit) {
        maxReferencedQubit = op.control!;
      }
    }

    int qubits = explicitQubits ?? (maxReferencedQubit + 1).clamp(1, maxQubits);
    if (qubits < 1) qubits = 1;
    if (qubits > maxQubits) {
      return ParsedCircuitResult.failure(
        'Circuit requires $qubits qubits, but QubitLab supports up to $maxQubits qubits.',
      );
    }
    if (maxReferencedQubit >= qubits) {
      return ParsedCircuitResult.failure(
        'A gate references qubit q$maxReferencedQubit, but circuit only has $qubits qubit(s) (q0..q${qubits - 1}).',
      );
    }

    // ASAP Wire Scheduling to assign columns (0..maxColumns-1)
    final nextCol = List<int>.filled(qubits, 0);
    final placedGates = <PlacedGate>[];
    int idSeq = 0;

    for (final op in parsedOperations) {
      int col;
      if (op.control == null) {
        col = nextCol[op.target];
        nextCol[op.target] = col + 1;
      } else {
        col = math.max(nextCol[op.control!], nextCol[op.target]);
        nextCol[op.control!] = col + 1;
        nextCol[op.target] = col + 1;
      }

      if (col >= maxColumns) {
        return ParsedCircuitResult.failure(
          'Circuit exceeds maximum width of $maxColumns columns (step ${col + 1} needed). Try reducing gate depth.',
        );
      }

      placedGates.add(PlacedGate(
        id: 'g${idSeq++}',
        type: op.type,
        column: col,
        target: op.target,
        control: op.control,
      ));
    }

    return ParsedCircuitResult.success(qubits: qubits, gates: placedGates);
  }

  static const Set<String> _singleQubitGates = {'h', 'x', 'not', 'y', 'z', 's', 't'};
  static const Set<String> _twoQubitGates = {'cx', 'cnot', 'cz'};

  static _GateParseResult _parseGateArgs(String gateName, String argsStr, int lineNum) {
    final lowerName = gateName.toLowerCase();
    if (!_singleQubitGates.contains(lowerName) && !_twoQubitGates.contains(lowerName)) {
      return _GateParseResult.error(
        'Line $lineNum: Gate "$gateName" is not supported. Supported gates: H, X, Y, Z, S, T, CNOT/CX, CZ.',
      );
    }

    if (argsStr.isEmpty) {
      return _GateParseResult.error('Line $lineNum: Gate "$gateName" requires qubit arguments.');
    }

    // Split arguments by comma
    final parts = argsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final qubitIndices = <int>[];
    final intRegex = RegExp(r'\b(\d+)\b');

    for (final part in parts) {
      final m = intRegex.firstMatch(part);
      if (m != null) {
        qubitIndices.add(int.parse(m.group(1)!));
      }
    }

    if (qubitIndices.length != parts.length || qubitIndices.isEmpty) {
      return _GateParseResult.error('Line $lineNum: Could not parse qubit indices from "($argsStr)".');
    }

    if (qubitIndices.length == 1) {
      return _resolveSingleQubitGate(lowerName, qubitIndices[0], lineNum);
    } else if (qubitIndices.length == 2) {
      return _resolveTwoQubitGate(lowerName, qubitIndices[0], qubitIndices[1], lineNum);
    } else {
      return _GateParseResult.error('Line $lineNum: Gate "$gateName" has too many arguments (${qubitIndices.length}).');
    }
  }

  static _GateParseResult _resolveSingleQubitGate(String name, int target, int lineNum) {
    if (target >= maxQubits) {
      return _GateParseResult.error('Line $lineNum: Qubit q$target exceeds maximum allowed qubits (supports up to $maxQubits qubits).');
    }

    GateType? type;
    switch (name) {
      case 'h':
        type = GateType.h;
        break;
      case 'x':
      case 'not':
        type = GateType.x;
        break;
      case 'y':
        type = GateType.y;
        break;
      case 'z':
        type = GateType.z;
        break;
      case 's':
        type = GateType.s;
        break;
      case 't':
        type = GateType.t;
        break;
      case 'cx':
      case 'cnot':
      case 'cz':
        return _GateParseResult.error('Line $lineNum: Gate "${name.toUpperCase()}" requires two qubits (control, target).');
      default:
        return _GateParseResult.error('Line $lineNum: Gate "$name" is not supported. Supported gates: H, X, Y, Z, S, T, CNOT/CX, CZ.');
    }

    return _GateParseResult.op(_RawOp(type: type, target: target));
  }

  static _GateParseResult _resolveTwoQubitGate(String name, int control, int target, int lineNum) {
    if (control >= maxQubits || target >= maxQubits) {
      return _GateParseResult.error('Line $lineNum: Qubit index exceeds maximum allowed qubits (supports up to $maxQubits qubits).');
    }
    if (control == target) {
      return _GateParseResult.error('Line $lineNum: Control and target qubits must be different (both are q$control).');
    }

    GateType? type;
    switch (name) {
      case 'cx':
      case 'cnot':
        type = GateType.cnot;
        break;
      case 'cz':
        type = GateType.cz;
        break;
      default:
        return _GateParseResult.error('Line $lineNum: Two-qubit gate "$name" is not supported. Supported two-qubit gates: CX, CNOT, CZ.');
    }

    return _GateParseResult.op(_RawOp(type: type, target: target, control: control));
  }
}

class _RawOp {
  final GateType type;
  final int target;
  final int? control;

  const _RawOp({required this.type, required this.target, this.control});
}

class _GateParseResult {
  final _RawOp? op;
  final String? error;

  const _GateParseResult.op(this.op) : error = null;
  const _GateParseResult.error(this.error) : op = null;
}
