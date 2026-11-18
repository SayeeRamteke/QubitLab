import 'package:flutter/material.dart';
import '../models/gate.dart';
import '../theme/app_theme.dart';

class LabStep {
  final int stepNumber;
  final String title;
  final String objective;
  final String physicsExplanation;
  final String hintIfWrong;
  final bool Function(List<PlacedGate> gates) validator;

  const LabStep({
    required this.stepNumber,
    required this.title,
    required this.objective,
    required this.physicsExplanation,
    required this.hintIfWrong,
    required this.validator,
  });
}

class GuidedLab {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String difficulty;
  final int qubits;
  final IconData icon;
  final Color color;
  final List<LabStep> steps;

  const GuidedLab({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.difficulty,
    required this.qubits,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

final List<GuidedLab> guidedLabs = [
  // 1. Superposition
  GuidedLab(
    id: 'superposition',
    title: 'Quantum Superposition',
    subtitle: 'Creating linear combinations of states',
    description: 'Learn how single-qubit quantum states exist in combinations of |0⟩ and |1⟩ until measured.',
    difficulty: 'Beginner',
    qubits: 1,
    icon: Icons.grain_rounded,
    color: AppColors.indigo,
    steps: [
      LabStep(
        stepNumber: 1,
        title: 'Apply Hadamard Gate',
        objective: 'Place an H gate on qubit q0.',
        physicsExplanation: 'The Hadamard (H) gate transforms the basis state |0⟩ into equal superposition (|0⟩ + |1⟩)/√2. Each state now has equal 50% probability of being measured.',
        hintIfWrong: 'Drag an H (Hadamard) gate from the palette onto wire q0.',
        validator: (gates) => gates.any((g) => g.type == GateType.h && g.target == 0),
      ),
      LabStep(
        stepNumber: 2,
        title: 'Add Relative Phase',
        objective: 'Add a Pauli-Z gate on q0 after the Hadamard.',
        physicsExplanation: 'The Pauli-Z gate flips the sign of |1⟩ to -|1⟩, turning |+⟩ into |−⟩ = (|0⟩ − |1⟩)/√2. While measurement probabilities remain 50/50, the quantum phase has rotated by 180°!',
        hintIfWrong: 'Place a Z gate on q0 at the next step after the H gate.',
        validator: (gates) {
          final hGate = gates.where((g) => g.type == GateType.h && g.target == 0).firstOrNull;
          final zGate = gates.where((g) => g.type == GateType.z && g.target == 0).firstOrNull;
          return hGate != null && zGate != null && zGate.column > hGate.column;
        },
      ),
      LabStep(
        stepNumber: 3,
        title: 'Verify Superposition',
        objective: 'Tap the Simulate button to observe measurement statistics and inspect the Bloch vector pointing along the -X axis.',
        physicsExplanation: 'In pure superposition with negative phase, the statevector points to the left pole (-X) on the Bloch sphere with coordinates (-1, 0, 0).',
        hintIfWrong: 'Tap Simulate to verify your superposition state!',
        validator: (gates) => gates.length >= 2,
      ),
    ],
  ),

  // 2. Quantum Interference
  GuidedLab(
    id: 'interference',
    title: 'Quantum Interference',
    subtitle: 'Mach-Zehnder Interferometer Analog',
    description: 'Witness constructive and destructive interference directly by recombining quantum paths.',
    difficulty: 'Intermediate',
    qubits: 1,
    icon: Icons.alt_route_rounded,
    color: AppColors.teal,
    steps: [
      LabStep(
        stepNumber: 1,
        title: 'First Beam Splitter (H)',
        objective: 'Place an H gate on q0 to split the initial state |0⟩ into two orthogonal paths.',
        physicsExplanation: 'In an optical interferometer, a 50:50 beam splitter divides light into two paths. In quantum computing, the Hadamard gate splits probability amplitude equally between |0⟩ and |1⟩.',
        hintIfWrong: 'Place an H gate on wire q0 at the first column.',
        validator: (gates) => gates.any((g) => g.type == GateType.h && g.target == 0),
      ),
      LabStep(
        stepNumber: 2,
        title: 'Phase Shifter (Z)',
        objective: 'Place a Z gate on q0 to induce a π phase shift on the second path.',
        physicsExplanation: 'The Z gate alters the relative phase of the amplitude on |1⟩. This phase difference is invisible under direct measurement, but will drastically alter interference when paths recombine.',
        hintIfWrong: 'Add a Z gate on q0 in the column after H.',
        validator: (gates) {
          final h1 = gates.where((g) => g.type == GateType.h && g.target == 0).firstOrNull;
          final z = gates.where((g) => g.type == GateType.z && g.target == 0).firstOrNull;
          return h1 != null && z != null && z.column > h1.column;
        },
      ),
      LabStep(
        stepNumber: 3,
        title: 'Second Beam Splitter (Recombination)',
        objective: 'Place a second H gate on q0 to recombine the paths.',
        physicsExplanation: 'When amplitudes recombine, paths leading to |0⟩ have opposite phases (+1 and -1) and cancel out completely (destructive interference). Paths leading to |1⟩ reinforce each other, yielding 100% |1⟩!',
        hintIfWrong: 'Place a second H gate on q0 after the Z gate.',
        validator: (gates) {
          final hGates = gates.where((g) => g.type == GateType.h && g.target == 0).toList();
          final zGates = gates.where((g) => g.type == GateType.z && g.target == 0).toList();
          if (hGates.length < 2 || zGates.isEmpty) return false;
          hGates.sort((a, b) => a.column.compareTo(b.column));
          return hGates[0].column < zGates[0].column && zGates[0].column < hGates[1].column;
        },
      ),
    ],
  ),

  // 3. Entanglement
  GuidedLab(
    id: 'entanglement',
    title: 'Quantum Entanglement',
    subtitle: 'Generating the Bell State |Φ+⟩',
    description: 'Create non-local quantum correlations where two qubits share an intertwined fate.',
    difficulty: 'Intermediate',
    qubits: 2,
    icon: Icons.hub_rounded,
    color: AppColors.purple,
    steps: [
      LabStep(
        stepNumber: 1,
        title: 'Superposition on Control Qubit',
        objective: 'Place an H gate on qubit q0.',
        physicsExplanation: 'To entangle two qubits, the control qubit must first exist in a superposition of both control states (|0⟩ and |1⟩).',
        hintIfWrong: 'Place an H gate on wire q0.',
        validator: (gates) => gates.any((g) => g.type == GateType.h && g.target == 0),
      ),
      LabStep(
        stepNumber: 2,
        title: 'Entangling CNOT Gate',
        objective: 'Place a CNOT gate with control on q0 and target on q1.',
        physicsExplanation: 'The CNOT flips q1 if and only if q0 is |1⟩. Because q0 is in superposition, the operation creates the Bell state (|00⟩ + |11⟩)/√2. Neither qubit has a definite state on its own, but their values are 100% correlated!',
        hintIfWrong: 'Drag a CNOT gate onto column 1 with control q0 and target q1.',
        validator: (gates) {
          final hasH = gates.any((g) => g.type == GateType.h && g.target == 0);
          final hasCnot = gates.any((g) => g.type == GateType.cnot && g.control == 0 && g.target == 1);
          return hasH && hasCnot;
        },
      ),
      LabStep(
        stepNumber: 3,
        title: 'Entanglement Verification',
        objective: 'Simulate the circuit to verify that only |00⟩ (50%) and |11⟩ (50%) are observed, with zero probability for |01⟩ and |10⟩.',
        physicsExplanation: 'Notice that individual Bloch vectors for q0 and q1 shrink to zero length! This is the definitive geometric signature of maximum entanglement (a completely mixed local state).',
        hintIfWrong: 'Tap Simulate to verify the Bell state output!',
        validator: (gates) => gates.length >= 2,
      ),
    ],
  ),

  // 4. Teleportation
  GuidedLab(
    id: 'teleportation',
    title: 'Quantum Teleportation',
    subtitle: 'Alice to Bob Quantum Protocol',
    description: 'Transmit an unknown quantum state across space using a shared Bell pair and classical corrections.',
    difficulty: 'Advanced',
    qubits: 3,
    icon: Icons.flight_takeoff_rounded,
    color: AppColors.orange,
    steps: [
      LabStep(
        stepNumber: 1,
        title: 'Step 1: Shared Bell Pair (Alice & Bob)',
        objective: 'Entangle Alice’s auxiliary qubit q1 with Bob’s qubit q2: Place an H on q1, then CNOT(q1 → q2).',
        physicsExplanation: 'Before teleporting, Alice and Bob must share an entangled Bell channel. Qubit q1 belongs to Alice, and q2 belongs to Bob.',
        hintIfWrong: 'First place an H gate on q1, then place a CNOT gate with control q1 and target q2.',
        validator: (gates) {
          final h1 = gates.any((g) => g.type == GateType.h && g.target == 1);
          final cnot12 = gates.any((g) => g.type == GateType.cnot && g.control == 1 && g.target == 2);
          return h1 && cnot12;
        },
      ),
      LabStep(
        stepNumber: 2,
        title: 'Step 2: Alice Entangles Payload',
        objective: 'Alice entangles her payload qubit q0 with her Bell half q1: Place CNOT(q0 → q1) then H(q0).',
        physicsExplanation: 'Alice performs a Bell-basis measurement on her two qubits (q0 and q1). The CNOT and H gates map the 4 Bell states onto computational basis states.',
        hintIfWrong: 'Place a CNOT with control q0 and target q1, followed by an H gate on q0.',
        validator: (gates) {
          final cnot01 = gates.any((g) => g.type == GateType.cnot && g.control == 0 && g.target == 1);
          final h0 = gates.any((g) => g.type == GateType.h && g.target == 0);
          return cnot01 && h0;
        },
      ),
      LabStep(
        stepNumber: 3,
        title: 'Step 3: Alice Measures (Classical Channel)',
        objective: 'Alice measures q0 and q1. Her 2 classical bits are communicated to Bob.',
        physicsExplanation: 'Alice’s measurement collapses her two qubits, instantly transferring the quantum state to Bob’s qubit q2 up to one of four Pauli operations (I, X, Z, XZ).',
        hintIfWrong: 'Proceed to Step 4 to apply Bob’s decoding corrections.',
        validator: (gates) => true,
      ),
      LabStep(
        stepNumber: 4,
        title: 'Step 4: Bob’s Unitary Corrections',
        objective: 'Apply Bob’s conditional corrections: Place CNOT(q1 → q2) and CZ(q0 → q2).',
        physicsExplanation: 'If Alice measured q1=1, Bob applies X (via CNOT). If Alice measured q0=1, Bob applies Z (via CZ). Bob’s qubit q2 is now in the exact state of Alice’s original payload!',
        hintIfWrong: 'Place a CNOT with control q1 and target q2, and a CZ gate with control q0 and target q2.',
        validator: (gates) {
          final hasCnot12 = gates.where((g) => g.type == GateType.cnot && g.control == 1 && g.target == 2).length >= 2;
          final hasCz02 = gates.any((g) => g.type == GateType.cz && (g.control == 0 || g.target == 0) && (g.control == 2 || g.target == 2));
          return hasCnot12 && hasCz02;
        },
      ),
    ],
  ),
];
