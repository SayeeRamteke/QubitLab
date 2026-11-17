"""Rule-based hint system for the Arena (no AI involved)."""


def make_hint(target: dict, gates, results: dict, exact_gates=None) -> str:
    types = {g.type for g in gates}
    if not gates:
        return "Hint: drag at least one gate onto a wire, then submit."
    if exact_gates is not None and len(gates) != exact_gates:
        return f"Hint: this challenge needs exactly {exact_gates} gates (you used {len(gates)})."
    wants_superposition = len(target) > 1
    if wants_superposition and "H" not in types:
        return "Hint: you need a Hadamard (H) gate to create superposition."
    if not wants_superposition and len(results) > 1:
        return "Hint: the target is one definite outcome. Your circuit leaves a superposition."
    if (len(target) == 2 and len(next(iter(target))) == 2
            and not (types & {"CNOT", "CZ"})):
        return "Hint: correlated outcomes need entanglement. Try a CNOT after your Hadamard."
    off = [k for k, p in target.items() if abs(p - results.get(k, 0.0)) > 0.05]
    if off:
        return f"Hint: outcome(s) {', '.join(off)} are off. Compare your histogram with the target."
    return "Hint: you produced an unexpected extra outcome. Check for stray gates."
