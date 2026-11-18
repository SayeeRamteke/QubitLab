# QubitLab
### An Interactive Learning Platform for Quantum Computing

QubitLab is a cross-platform mobile application designed to make quantum computing easier to explore through interactive lessons, guided experiments and a hands-on quantum circuit builder.

Instead of learning quantum concepts only through theory, learners can build circuits, simulate them, visualise measurement probabilities and Bloch spheres, and inspect the mathematics behind each operation.

---

## Features

### 1. Home Dashboard
- Displays XP points, daily streak and learning progress.
- Resume Learning functionality.
- Daily Predict challenges to test quantum intuition.

### 2. Learn
- 12 lessons organised into 4 modules:
  - The Qubit
  - Single-Qubit Gates
  - Multi-Qubit Systems
  - Quantum Algorithms
- Interactive lessons, videos and quizzes.
- Mini-labs to reinforce theoretical concepts.

### 3. Guided Labs

Step-by-step quantum experiments:

- **Superposition:** Explore single-qubit superposition.
- **Interference:** Understand constructive and destructive interference.
- **Entanglement:** Construct Bell states using H and CNOT gates.
- **Teleportation:** Explore quantum teleportation using three qubits.

Each experiment provides circuit validation, hints and explanations.

### 4. Quantum Circuit Lab

- Interactive circuit composer.
- Drag-and-drop quantum gates.
- Supported gates: H, X, Y, Z, S, T, CNOT and CZ.
- Quantum circuit simulation using Qiskit Aer.
- Measurement probability visualisation.
- 3D Bloch sphere visualisation.
- Math Mode for step-by-step quantum state calculations.
- Qiskit Python and OpenQASM conversion.
- Save and reload circuits.

### 5. Arena
- Circuit-building challenges.
- Target probability distribution matching.
- Automated challenge verification.
- Contextual hints and XP rewards.

### 6. Gamification
- XP-based reward system.
- Daily learning streaks.
- Lesson completion tracking.
- Challenge progress tracking.

---

## Technology Stack

| Layer | Technologies |
|---|---|
| Frontend | Flutter, Dart, Material 3 |
| State Management | Provider |
| Backend | Python, FastAPI, Uvicorn |
| Quantum Computing | Qiskit, Qiskit Aer |
| Numerical Computing | NumPy |
| Database | SQLite |
| ORM | SQLAlchemy |
| Validation | Pydantic |
| Charts | fl_chart |
| Mathematical Rendering | flutter_math_fork |
| Networking | HTTP |
| Local Preferences | SharedPreferences |

---

## System Architecture

QubitLab follows a three-tier client-server architecture.

```text
          FLUTTER MOBILE APPLICATION
    -------------------------------------
       Home | Learn | Guided Labs
             Circuit Lab | Arena
    -------------------------------------
                    |
                 HTTP/REST
                    |
                    v
             FASTAPI BACKEND
    -------------------------------------
       Authentication and User Data
       Learning Progress Management
       Circuit Simulation
       Bloch Sphere Calculations
       Mathematical Breakdown
       Challenge Verification
    -------------------------------------
                    |
              QISKIT / AER
                    |
                    v
               SQLITE DATABASE
    -------------------------------------
       Users
       Lessons
       Progress
       Challenges
       Saved Circuits
    -------------------------------------
