/// Lesson content lives in the app. Ids must match backend/seed.py.
///
/// VIDEOS: paste a YouTube video ID into `youtubeId` (the part after "v=" in
/// https://www.youtube.com/watch?v=XXXXXXXXXXX). Leave '' to hide the player.
class Lesson {
  final int id;
  final int module; // index into `modules`
  final String title;
  final List<String> paragraphs;
  final String youtubeId;
  final int qubits;
  final String goal;
  final Map<String, double> target;
  final String question;
  final List<String> options;
  final int correct;

  const Lesson({
    required this.id,
    required this.module,
    required this.title,
    required this.paragraphs,
    this.youtubeId = '',
    required this.qubits,
    required this.goal,
    required this.target,
    required this.question,
    required this.options,
    required this.correct,
  });
}

Iterable<Lesson> lessonsOf(int module) => lessonsData.where((l) => l.module == module);

const lessonsData = <Lesson>[
  Lesson(
    id: 1,
    module: 0,
    title: 'Meet the qubit',
    youtubeId: 'HSM1GfukQMI&t=18s',
    paragraphs: [
      'A classical bit is either 0 or 1. A qubit is the quantum version: when you measure it you still get 0 or 1, but before measuring it can be in a blend of both.',
      'Every qubit starts in the state |0>. Gates are the operations that change it. The X gate is the simplest: it flips |0> into |1>.',
    ],
    qubits: 1,
    goal: 'Prepare the |1> state by dragging an X gate onto the wire, then press Check.',
    target: {'1': 1.0},
    question: 'Which state does every qubit start in?',
    options: ['|0>', '|1>', 'Both at once', 'It is random'],
    correct: 0,
  ),
  Lesson(
    id: 2,
    module: 0,
    title: 'Superposition',
    youtubeId: 'IHDMJqJHCQg',
    paragraphs: [
      'A qubit in superposition has an amplitude for |0> and an amplitude for |1>. Measuring it picks one outcome with probability equal to the amplitude squared.',
      'The Hadamard (H) gate turns |0> into an equal superposition: a perfect quantum coin flip.',
    ],
    qubits: 1,
    goal: 'Create a 50% / 50% superposition with a single H gate.',
    target: {'0': 0.5, '1': 0.5},
    question: 'Measuring an equal superposition many times gives...',
    options: ['Always 0', 'Always 1', 'About half 0 and half 1', 'Nothing'],
    correct: 2,
  ),
  Lesson(
    id: 3,
    module: 1,
    title: 'Pauli gates X, Y, Z',
    youtubeId: 'jFLlL8bCqxQ',
    paragraphs: [
      'The Pauli gates rotate a qubit by 180 degrees around one axis. X flips 0 and 1, Y flips and adds a phase, and Z leaves |0> alone but flips the sign of |1>.',
      'Phase is invisible to a direct measurement, but it matters a lot once gates start interfering with each other.',
    ],
    qubits: 1,
    goal: 'Use the Y gate to prepare |1>. It flips the qubit just like X.',
    target: {'1': 1.0},
    question: 'Which Pauli gate flips |0> to |1> with no extra phase?',
    options: ['X', 'Z', 'S', 'T'],
    correct: 0,
  ),
  Lesson(
    id: 4,
    module: 1,
    title: 'Hadamard and interference',
    youtubeId: 'G9d0QWM82sU',
    paragraphs: [
      'Quantum amplitudes can cancel or reinforce each other, like waves. Applying H once creates a superposition. Applying H a second time makes the two paths interfere.',
      'The result is that the qubit returns to |0> with certainty. Interference is the engine behind quantum algorithms.',
    ],
    qubits: 1,
    goal: 'Apply H twice in a row and watch the superposition cancel out.',
    target: {'0': 1.0},
    question: 'What does H followed by H do to |0>?',
    options: ['Returns it to |0>', 'Flips it to |1>', 'Makes it random', 'Entangles it'],
    correct: 0,
  ),
  Lesson(
    id: 5,
    module: 2,
    title: 'The CNOT gate',
    youtubeId: 'yg3SckRKDz4',
    paragraphs: [
      'CNOT uses two qubits: a control and a target. If the control is |1> it flips the target, otherwise it does nothing. In the Lab, the wire you drop it on is the control.',
      'It is the quantum version of a conditional: "if control then flip target".',
    ],
    qubits: 2,
    goal: 'Put X on q0, then a CNOT with control q0, so both qubits end up as 1 (|11>).',
    target: {'11': 1.0},
    question: 'When does CNOT flip the target qubit?',
    options: ['Always', 'When the control is |1>', 'When the control is |0>', 'Never'],
    correct: 1,
  ),
  Lesson(
    id: 6,
    module: 2,
    title: 'Entanglement and Bell states',
    youtubeId: 'GSsElSQgMbU&t=1900s',
    paragraphs: [
      'Apply H to the control and then CNOT, and the two qubits become entangled: they are perfectly correlated, yet neither has a definite value on its own.',
      'This is the Bell state. Long-press a qubit label in the Lab afterwards: its Bloch vector shrinks to zero, which is the signature of entanglement.',
    ],
    qubits: 2,
    goal: 'Build the Bell state: H on q0, then CNOT from q0 to q1.',
    target: {'00': 0.5, '11': 0.5},
    question: 'In a Bell state, which outcomes can you measure?',
    options: ['00 and 11 only', '01 and 10 only', 'All four equally', 'Only 00'],
    correct: 0,
  ),
  Lesson(
    id: 7,
    module: 3,
    title: 'Deutsch-Jozsa (1 bit)',
    youtubeId: '7MdEHsRZxvo',
    paragraphs: [
      'The Deutsch-Jozsa algorithm decides whether a function is constant or balanced with a single query, where a classical computer may need two.',
      'In the 1-bit phase-oracle version: H, then the oracle, then H. A constant oracle leaves the qubit at 0. A balanced oracle (a Z gate here) makes it read 1.',
    ],
    qubits: 1,
    goal: 'Build the balanced version: H, then Z (the oracle), then H. The qubit should read 1.',
    target: {'1': 1.0},
    question: 'In this version, what does measuring 1 tell you?',
    options: ['The function is balanced', 'The function is constant', 'The circuit failed', 'Nothing'],
    correct: 0,
  ),
  Lesson(
    id: 8,
    module: 3,
    title: "Grover's search (2 qubits)",
    youtubeId: 'hnpjC8WQVrQ',
    paragraphs: [
      "Grover's algorithm finds a marked item in an unsorted list faster than checking one by one. With 2 qubits there are 4 items, and one Grover iteration finds the marked one with 100% probability.",
      'Recipe for marking |11>: H on both, CZ (the oracle), H on both, X on both, CZ, X on both, H on both. The middle part is the diffuser.',
    ],
    qubits: 2,
    goal: 'Build one Grover iteration so that |11> is measured with 100% probability.',
    target: {'11': 1.0},
    question: 'What does the diffuser step do?',
    options: [
      'Amplifies the marked state',
      'Measures the qubits',
      'Resets the circuit',
      'Adds noise',
    ],
    correct: 0,
  ),
];
