"""Pydantic models = the JSON contract between Flutter and FastAPI."""
from typing import Literal, Optional
from pydantic import BaseModel, Field, model_validator

SINGLE_QUBIT = {"H", "X", "Y", "Z", "S", "T"}
TWO_QUBIT = {"CNOT", "CZ"}


class Gate(BaseModel):
    type: Literal["H", "X", "Y", "Z", "S", "T", "CNOT", "CZ"]
    target: int = Field(ge=0)
    control: Optional[int] = Field(default=None, ge=0)

    @model_validator(mode="after")
    def check_control(self):
        if self.type in TWO_QUBIT:
            if self.control is None:
                raise ValueError(f"{self.type} requires a 'control' qubit")
            if self.control == self.target:
                raise ValueError("control and target must be different qubits")
        return self


class CircuitRequest(BaseModel):
    qubits: int = Field(ge=1, le=5)
    gates: list[Gate] = []

    @model_validator(mode="after")
    def check_bounds(self):
        for g in self.gates:
            if g.target >= self.qubits or (g.control is not None and g.control >= self.qubits):
                raise ValueError(f"Gate {g.type} references a qubit outside 0..{self.qubits - 1}")
        return self


class SimulateResponse(BaseModel):
    results: dict[str, float]


class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=4)


class UserOut(BaseModel):
    id: int
    username: str
    xp: int
    streak_days: int
    model_config = {"from_attributes": True}


class CircuitSave(BaseModel):
    user_id: int
    name: str = Field(min_length=1, max_length=100)
    qubits: int = Field(ge=1, le=5, default=2)
    circuit_json: list[dict]


class CircuitOut(BaseModel):
    id: int
    user_id: int
    name: str
    qubits: int
    circuit_json: list[dict]
    model_config = {"from_attributes": True}


class ChallengeOut(BaseModel):
    id: int
    title: str
    description: str
    qubits: int
    target_json_state: dict
    xp_reward: int
    model_config = {"from_attributes": True}


# ---------- Phase 5/6 additions ----------
class SubmitBody(BaseModel):
    user_id: int
    qubits: int = Field(ge=1, le=5)
    gates: list[Gate] = []


class SubmitResult(BaseModel):
    passed: bool
    results: dict[str, float]
    target: dict
    xp_awarded: int
    hint: Optional[str] = None


class LessonOut(BaseModel):
    id: int
    module_name: str
    title: str
    order_index: int
    model_config = {"from_attributes": True}


class LessonComplete(BaseModel):
    user_id: int


class ProgressOut(BaseModel):
    completed_lessons: list[int]
    completed_challenges: list[int]


class BlochVector(BaseModel):
    qubit: int
    x: float
    y: float
    z: float


class BlochOut(BaseModel):
    vectors: list[BlochVector]
