import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum GateType { h, x, y, z, s, t, cnot, cz }

extension GateTypeX on GateType {
  /// Name used in the JSON contract with FastAPI.
  String get apiName => switch (this) {
        GateType.h => 'H',
        GateType.x => 'X',
        GateType.y => 'Y',
        GateType.z => 'Z',
        GateType.s => 'S',
        GateType.t => 'T',
        GateType.cnot => 'CNOT',
        GateType.cz => 'CZ',
      };

  bool get isTwoQubit => this == GateType.cnot || this == GateType.cz;

  Color get color => switch (this) {
        GateType.h => AppColors.indigo,
        GateType.x => AppColors.orange,
        GateType.y => AppColors.green,
        GateType.z => AppColors.purple,
        GateType.s => AppColors.teal,
        GateType.t => AppColors.pink,
        GateType.cnot => AppColors.ink,
        GateType.cz => const Color(0xFF4A4A5C),
      };

  String get title => switch (this) {
        GateType.h => 'Hadamard',
        GateType.x => 'Pauli-X (NOT)',
        GateType.y => 'Pauli-Y',
        GateType.z => 'Pauli-Z',
        GateType.s => 'S (phase) gate',
        GateType.t => 'T gate',
        GateType.cnot => 'CNOT (controlled-X)',
        GateType.cz => 'Controlled-Z',
      };

  String get description => switch (this) {
        GateType.h => 'Puts a qubit into an equal superposition of |0> and |1>.',
        GateType.x => 'Flips |0> to |1> and |1> to |0>, like a classical NOT.',
        GateType.y => 'Flips the qubit and adds an imaginary phase.',
        GateType.z => 'Leaves |0> alone and flips the sign (phase) of |1>.',
        GateType.s => 'Adds a 90-degree phase to |1>.',
        GateType.t => 'Adds a 45-degree phase to |1>.',
        GateType.cnot => 'Flips the target qubit only when the control qubit is |1>. Creates entanglement.',
        GateType.cz => 'Flips the phase of |11>. Symmetric in both qubits.',
      };
}

/// One gate placed on the circuit grid (a "GateInteraction").
class PlacedGate {
  final String id;
  final GateType type;
  final int column; // time step (left to right)
  final int target;
  final int? control; // only for CNOT / CZ

  const PlacedGate({
    required this.id,
    required this.type,
    required this.column,
    required this.target,
    this.control,
  });

  bool involves(int qubit) => target == qubit || control == qubit;

  PlacedGate swapped() => PlacedGate(
        id: id,
        type: type,
        column: column,
        target: control ?? target,
        control: control == null ? null : target,
      );

  Map<String, dynamic> toJson() => {
        'type': type.apiName,
        'target': target,
        'column': column,
        if (control != null) 'control': control,
      };
}

/// Data carried while dragging (from palette, or an already-placed gate).
class DragPayload {
  final GateType type;
  final String? fromId; // non-null when moving a gate already on the grid
  const DragPayload(this.type, [this.fromId]);
}
