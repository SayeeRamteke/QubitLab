class PredictOption {
  final String label;
  final bool isCorrect;
  final String explanation;

  const PredictOption({
    required this.label,
    required this.isCorrect,
    required this.explanation,
  });
}

class DailyPredictChallenge {
  final String id;
  final String title;
  final String concept;
  final int qubits;
  final List<String> circuitSummary;
  final String question;
  final List<PredictOption> options;
  final int xpReward;

  const DailyPredictChallenge({
    required this.id,
    required this.title,
    required this.concept,
    required this.qubits,
    required this.circuitSummary,
    required this.question,
    required this.options,
    this.xpReward = 15,
  });
}

final List<DailyPredictChallenge> dailyChallenges = [
  const DailyPredictChallenge(
    id: 'daily_interference',
    title: 'Quantum Interference Test',
    concept: 'Mach-Zehnder Analog',
    qubits: 1,
    circuitSummary: ['H', 'Z', 'H'],
    question: 'Qubit q0 starts in |0⟩. After applying H → Z → H, what is the measurement outcome?',
    options: [
      PredictOption(
        label: '|1⟩ with 100% probability',
        isCorrect: true,
        explanation: 'Correct! The first H creates equal superposition (|0⟩+|1⟩)/√2. The Z gate flips the phase of |1⟩ to produce (|0⟩-|1⟩)/√2. The final H causes destructive interference on |0⟩ (1 - 1 = 0) and constructive interference on |1⟩, guaranteeing output |1⟩!',
      ),
      PredictOption(
        label: '|0⟩ with 100% probability',
        isCorrect: false,
        explanation: 'Incorrect: The Pauli-Z gate introduced a π relative phase flip (-|1⟩). When the second Hadamard recombines the paths, the amplitudes for |0⟩ destructively cancel out!',
      ),
      PredictOption(
        label: '50% |0⟩ and 50% |1⟩',
        isCorrect: false,
        explanation: 'Incorrect: You might suspect 50/50 randomness, but quantum interference causes the two paths to interfere. The phase flip produces destructive interference on |0⟩ and constructive on |1⟩.',
      ),
    ],
  ),
  const DailyPredictChallenge(
    id: 'daily_bell',
    title: 'Entangled State Prediction',
    concept: 'Bell State Formation',
    qubits: 2,
    circuitSummary: ['q0: H', 'CNOT(q0 → q1)'],
    question: 'Both qubits start in |00⟩. After H on q0 and CNOT(q0 → q1), which states can be measured?',
    options: [
      PredictOption(
        label: '|00⟩ and |11⟩ equally (50% each)',
        isCorrect: true,
        explanation: 'Correct! Hadamard on q0 creates (|0⟩+|1⟩)|0⟩ = (|00⟩+|10⟩)/√2. Then CNOT flips q1 only when q0 is |1⟩, resulting in the maximally entangled Bell state (|00⟩+|11⟩)/√2.',
      ),
      PredictOption(
        label: '|01⟩ and |10⟩ equally',
        isCorrect: false,
        explanation: 'Incorrect: CNOT only flips target q1 when control q0 is |1⟩. Since q0 was in |0⟩ with 50% probability, q1 remains |0⟩, yielding |00⟩, never |01⟩ or |10⟩.',
      ),
      PredictOption(
        label: 'All 4 basis states (|00⟩, |01⟩, |10⟩, |11⟩) equally at 25%',
        isCorrect: false,
        explanation: 'Incorrect: The circuit does not create uniform randomness. The CNOT gate creates strict quantum correlation between the two qubits, eliminating |01⟩ and |10⟩ completely.',
      ),
    ],
  ),
  const DailyPredictChallenge(
    id: 'daily_kickback',
    title: 'Phase Kickback Effect',
    concept: 'Oracle Eigenvalue Inversion',
    qubits: 2,
    circuitSummary: ['q0: H', 'q1: X, H', 'CNOT(q0 → q1)', 'q0: H'],
    question: 'With target q1 initialized in the |−⟩ state, what happens to control qubit q0 after CNOT and H?',
    options: [
      PredictOption(
        label: 'q0 is measured as |1⟩ with 100% certainty',
        isCorrect: true,
        explanation: 'Correct! Because q1 is in the eigenvector |−⟩ with eigenvalue -1, the CNOT kicks back a negative phase onto control q0 when q0 is |1⟩. The subsequent Hadamard converts this phase difference into a deterministic |1⟩ measurement!',
      ),
      PredictOption(
        label: 'q0 is measured as |0⟩ with 100% certainty',
        isCorrect: false,
        explanation: 'Incorrect: Without the phase kickback, q0 would return to |0⟩. However, the eigenvalue -1 from target q1 flips the phase of q0, turning |+⟩ into |−⟩ which transforms to |1⟩ under H.',
      ),
      PredictOption(
        label: 'q0 remains in a 50/50 superposition',
        isCorrect: false,
        explanation: 'Incorrect: The final Hadamard gate on q0 interferes the amplitudes, converting the phase information back into computational basis certainty (|1⟩).',
      ),
    ],
  ),
  const DailyPredictChallenge(
    id: 'daily_pauli_y',
    title: 'Pauli-Y Transformation',
    concept: 'Complex Phase Rotation',
    qubits: 1,
    circuitSummary: ['X', 'Y'],
    question: 'Qubit q0 starts in |0⟩. We apply Pauli-X followed by Pauli-Y. What is the resulting state up to global phase?',
    options: [
      PredictOption(
        label: '|0⟩ with 100% probability (with -i global phase)',
        isCorrect: true,
        explanation: 'Correct! X|0⟩ = |1⟩, then Y|1⟩ = -i|0⟩. Since global phase does not alter measurement outcomes, measuring this state yields |0⟩ with 100% certainty.',
      ),
      PredictOption(
        label: '|1⟩ with 100% probability',
        isCorrect: false,
        explanation: 'Incorrect: X maps |0⟩ to |1⟩, but Y is a bit-flip AND phase-flip (Y = i|0⟩⟨1| - i|1⟩⟨0|), which flips |1⟩ back to |0⟩.',
      ),
      PredictOption(
        label: 'Equal superposition of |0⟩ and |1⟩',
        isCorrect: false,
        explanation: 'Incorrect: Both X and Y are Pauli operations that swap basis states without generating superposition from computational states.',
      ),
    ],
  ),
  const DailyPredictChallenge(
    id: 'daily_hadamard_cnot',
    title: 'Bell State |Ψ+⟩ Predictor',
    concept: 'Entangled Superposition',
    qubits: 2,
    circuitSummary: ['q0: H', 'q1: X', 'CNOT(q0 → q1)'],
    question: 'Qubit q0 has an H gate and qubit q1 has an X gate. Then CNOT(q0 → q1) is applied. What are the possible measurement outcomes?',
    options: [
      PredictOption(
        label: '50% |01⟩ and 50% |10⟩ (|Ψ+⟩)',
        isCorrect: true,
        explanation: 'Correct! Initializing q1 with X yields state (|01⟩ + |11⟩)/√2 after the Hadamard on q0. When CNOT flips q1 on control=1, |11⟩ becomes |10⟩, creating the entangled Bell state |Ψ+⟩ = (|01⟩ + |10⟩)/√2.',
      ),
      PredictOption(
        label: '50% |00⟩ and 50% |11⟩ (|Φ+⟩)',
        isCorrect: false,
        explanation: 'Incorrect: |00⟩ and |11⟩ is the standard |Φ+⟩ state obtained when q1 starts in |0⟩. Because q1 was flipped to |1⟩ by the X gate, the output is orthogonal (|Ψ+⟩).',
      ),
      PredictOption(
        label: 'Deterministic 100% |11⟩',
        isCorrect: false,
        explanation: 'Incorrect: The Hadamard gate on q0 creates a superposition, ensuring an entangled two-state distribution rather than a deterministic single outcome.',
      ),
    ],
  ),
];

DailyPredictChallenge getTodayChallenge() {
  // Use day of year to cycle through challenges
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return dailyChallenges[dayOfYear % dailyChallenges.length];
}
