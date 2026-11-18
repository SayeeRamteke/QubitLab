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


# ---------- Math Mode: Step-by-step matrix multiplication ----------
from qiskit.quantum_info import Operator


def _fmt_val(v) -> str:
    if abs(v.imag) < 1e-4:
        r = v.real
        if abs(r) < 1e-4:
            return "0"
        if abs(r - 1.0) < 1e-3:
            return "1"
        if abs(r + 1.0) < 1e-3:
            return "-1"
        if abs(abs(r) - 1 / np.sqrt(2)) < 1e-3:
            return "\\frac{1}{\\sqrt{2}}" if r > 0 else "-\\frac{1}{\\sqrt{2}}"
        if abs(abs(r) - 0.5) < 1e-3:
            return "\\frac{1}{2}" if r > 0 else "-\\frac{1}{2}"
        return f"{r:.3f}"
    if abs(v.real) < 1e-4:
        im = v.imag
        if abs(im - 1.0) < 1e-3:
            return "i"
        if abs(im + 1.0) < 1e-3:
            return "-i"
        return f"{im:.3f}i"
    sgn = "+" if v.imag > 0 else "-"
    return f"{v.real:.3f}{sgn}{abs(v.imag):.3f}i"


def _mat_to_latex(mat) -> str:
    rows = []
    for r in mat:
        rows.append(" & ".join(_fmt_val(x) for x in r))
    return "\\begin{bmatrix} " + " \\\\ ".join(rows) + " \\end{bmatrix}"


def _vec_to_latex(vec) -> str:
    rows = [_fmt_val(x) for x in vec]
    return "\\begin{bmatrix} " + " \\\\ ".join(rows) + " \\end{bmatrix}"


def _dirac_to_latex(sv: Statevector, qubits: int) -> str:
    terms = []
    data = sv.data
    for i, amp in enumerate(data):
        if abs(amp) > 1e-4:
            bs = format(i, f"0{qubits}b")
            val_str = _fmt_val(amp)
            if val_str == "1":
                terms.append(f"\\vert {bs} \\rangle")
            elif val_str == "-1":
                terms.append(f"-\\vert {bs} \\rangle")
            else:
                terms.append(f"{val_str}\\vert {bs} \\rangle")
    if not terms:
        return "0"
    res = terms[0]
    for t in terms[1:]:
        if t.startswith("-"):
            res += " - " + t[1:]
        else:
            res += " + " + t
    return res


def _describe_slice(slice_gates) -> tuple[str, str]:
    labels = []
    descs = []
    for g in slice_gates:
        if g.type == "H":
            labels.append(f"H(q{g.target})")
            descs.append(f"Hadamard on q{g.target} puts it into equal superposition.")
        elif g.type == "X":
            labels.append(f"X(q{g.target})")
            descs.append(f"Pauli-X (NOT) on q{g.target} flips |0> and |1>.")
        elif g.type == "Y":
            labels.append(f"Y(q{g.target})")
            descs.append(f"Pauli-Y on q{g.target} flips the bit with imaginary phase.")
        elif g.type == "Z":
            labels.append(f"Z(q{g.target})")
            descs.append(f"Pauli-Z on q{g.target} adds a π phase flip to |1>.")
        elif g.type == "S":
            labels.append(f"S(q{g.target})")
            descs.append(f"S gate on q{g.target} applies a 90° phase shift to |1>.")
        elif g.type == "T":
            labels.append(f"T(q{g.target})")
            descs.append(f"T gate on q{g.target} applies a 45° phase shift to |1>.")
        elif g.type == "CNOT":
            labels.append(f"CNOT(q{g.control} \\to q{g.target})")
            descs.append(f"CNOT from control q{g.control} to target q{g.target} creates entanglement.")
        elif g.type == "CZ":
            labels.append(f"CZ(q{g.control}, q{g.target})")
            descs.append(f"Controlled-Z inverts the phase of state |11>.")
    gate_label = " \\otimes ".join(labels) if len(labels) > 1 else labels[0]
    description = " ".join(descs)
    return gate_label, description


def math_breakdown(req: CircuitRequest) -> dict:
    qubits = req.qubits
    dim = 2 ** qubits

    # Initial state |0...0>
    sv = Statevector.from_label("0" * qubits)
    input_latex = _vec_to_latex(sv.data)

    # Group gates into slices by column or sequential
    slices = []
    has_columns = any(g.column is not None for g in req.gates)
    if has_columns:
        col_map = {}
        for g in req.gates:
            col = g.column if g.column is not None else 0
            col_map.setdefault(col, []).append(g)
        for col in sorted(col_map.keys()):
            slices.append(col_map[col])
    else:
        for g in req.gates:
            slices.append([g])

    steps = []
    for step_idx, slice_gates in enumerate(slices):
        sub_qc = QuantumCircuit(qubits)
        for g in slice_gates:
            if g.type == "H":
                sub_qc.h(g.target)
            elif g.type == "X":
                sub_qc.x(g.target)
            elif g.type == "Y":
                sub_qc.y(g.target)
            elif g.type == "Z":
                sub_qc.z(g.target)
            elif g.type == "S":
                sub_qc.s(g.target)
            elif g.type == "T":
                sub_qc.t(g.target)
            elif g.type == "CNOT":
                sub_qc.cx(g.control, g.target)
            elif g.type == "CZ":
                sub_qc.cz(g.control, g.target)

        op = Operator(sub_qc)
        u_mat = op.data
        u_latex = _mat_to_latex(u_mat)
        in_vec_latex = _vec_to_latex(sv.data)

        # Evolve state: |psi_{out}> = U |psi_{in}>
        sv = sv.evolve(op)
        out_vec_latex = _vec_to_latex(sv.data)

        gate_label, description = _describe_slice(slice_gates)
        calc_latex = f"{u_latex} \\times {in_vec_latex} = {out_vec_latex}"
        dirac = _dirac_to_latex(sv, qubits)
        probs = {str(k): round(float(v), 4) for k, v in sorted(sv.probabilities_dict().items())}

        steps.append({
            "step_index": step_idx + 1,
            "title": f"Step {step_idx + 1}: {gate_label}",
            "description": description,
            "gate_label": gate_label,
            "operator_latex": u_latex,
            "input_state_latex": in_vec_latex,
            "calculation_latex": calc_latex,
            "output_state_latex": out_vec_latex,
            "dirac_latex": dirac,
            "probabilities": probs,
        })

    return {
        "qubits": qubits,
        "dimension": dim,
        "input_state_latex": input_latex,
        "steps": steps,
    }
