"""Quantum engine: turns the JSON gate list into a Qiskit circuit and simulates it."""
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

from schemas import CircuitRequest

SHOTS = 1024
_simulator = AerSimulator()


def build_circuit(req: CircuitRequest) -> QuantumCircuit:
    qc = QuantumCircuit(req.qubits)
    for g in req.gates:
        if g.type == "H":
            qc.h(g.target)
        elif g.type == "X":
            qc.x(g.target)
        elif g.type == "Y":
            qc.y(g.target)
        elif g.type == "Z":
            qc.z(g.target)
        elif g.type == "S":
            qc.s(g.target)
        elif g.type == "T":
            qc.t(g.target)
        elif g.type == "CNOT":
            qc.cx(g.control, g.target)
        elif g.type == "CZ":
            qc.cz(g.control, g.target)
    return qc


def simulate(req: CircuitRequest, shots: int = SHOTS) -> dict[str, float]:
    """Returns {bitstring: probability}. NOTE: Qiskit prints qubit 0 as the
    RIGHTMOST bit, so "01" means q0=1, q1=0."""
    qc = build_circuit(req)
    qc.measure_all()
    counts = _simulator.run(qc, shots=shots).result().get_counts()
    return {k: round(v / shots, 4) for k, v in sorted(counts.items())}


# ---------- Bloch vectors (Qubit Inspector) ----------
import numpy as np
from qiskit.quantum_info import Statevector, partial_trace, Pauli


def bloch_vectors(req: CircuitRequest) -> list[dict]:
    """Per-qubit Bloch vector. Length < 1 means the qubit is entangled with others."""
    sv = Statevector.from_instruction(build_circuit(req))
    out = []
    for q in range(req.qubits):
        others = [i for i in range(req.qubits) if i != q]
        state = partial_trace(sv, others) if others else sv
        x, y, z = (round(float(np.real(state.expectation_value(Pauli(p)))), 4) + 0.0
                   for p in "XYZ")
        out.append({"qubit": q, "x": x, "y": y, "z": z})
    return out
