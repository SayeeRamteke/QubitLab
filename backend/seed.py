from models import Challenge, Lesson

# IDs here MUST match the lesson ids in the Flutter app (data/lessons_data.dart).
LESSONS = [
    (1, "The Qubit", "Meet the qubit"),
    (2, "The Qubit", "Superposition"),
    (3, "Single-Qubit Gates", "Pauli gates X, Y, Z"),
    (4, "Single-Qubit Gates", "Hadamard and interference"),
    (5, "Multi-Qubit Systems", "The CNOT gate"),
    (6, "Multi-Qubit Systems", "Entanglement and Bell states"),
    (7, "Quantum Algorithms", "Deutsch-Jozsa (1 bit)"),
    (8, "Quantum Algorithms", "Grover's search (2 qubits)"),
]

CHALLENGES = [
    dict(title="The Coin Flip", qubits=1, xp_reward=10,
         description="Get 50% |0> and 50% |1>.",
         target_json_state={"0": 0.5, "1": 0.5}),
    dict(title="The Reversal", qubits=1, xp_reward=10, exact_gates=2,
         description="Flip a qubit 0 -> 1 -> 0 using exactly two gates.",
         target_json_state={"0": 1.0}),
    dict(title="Spooky Action", qubits=2, xp_reward=20,
         description="Create the Bell state: 50% |00>, 50% |11>.",
         target_json_state={"00": 0.5, "11": 0.5}),
    dict(title="Anti-Correlation", qubits=2, xp_reward=25,
         description="Create the Psi+ Bell state: 50% |01>, 50% |10>.",
         target_json_state={"01": 0.5, "10": 0.5}),
    dict(title="The Hidden State", qubits=2, xp_reward=30,
         description="Equal superposition (25% each) using phase kickback.",
         target_json_state={"00": 0.25, "01": 0.25, "10": 0.25, "11": 0.25}),
]


def seed_all(db):
    if db.query(Lesson).count() == 0:
        db.add_all([Lesson(id=i, module_name=m, title=t, order_index=i)
                    for i, m, t in LESSONS])
    if db.query(Challenge).count() == 0:
        db.add_all([Challenge(**c) for c in CHALLENGES])
    db.commit()
