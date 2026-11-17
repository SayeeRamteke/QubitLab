# QubitLab: complete project (Phases 1-6)

```
qubitlab/
  backend/            FastAPI + Qiskit + SQLite   (Phases 1, 2 + login, lessons, challenges)
  flutter/lib/        Flutter source               (Phases 3-6). Drop into a new Flutter project.
```

## 1. Combine everything (one-time)

### Backend
```bash
cd qubitlab/backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
rm -f qubitlab.db            # IMPORTANT if you ran the Phase 1-2 version (new columns/tables)
python test_api.py           # must end with: ALL BACKEND TESTS PASSED
uvicorn main:app --reload
```
Check http://127.0.0.1:8000/docs loads.

### Flutter (Android Studio)
```bash
cd qubitlab
flutter create qubitlab_app
cd qubitlab_app
rm -rf lib test/widget_test.dart
cp -r ../flutter/lib ./lib
flutter pub add provider http fl_chart google_fonts youtube_player_flutter confetti shared_preferences
flutter analyze
```
Open `qubitlab_app` in Android Studio (File > Open).

### Android manifest (REQUIRED, otherwise every API call fails)
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:usesCleartextTraffic="true"
        android:label="qubitlab_app" ...>
```
(`usesCleartextTraffic` allows plain http:// to the dev server. Android blocks it by default.)

### Run
1. Terminal 1: backend running (`uvicorn main:app --reload`).
2. Android Studio > Device Manager > start an emulator (Pixel, API 30+ with Google APIs).
3. Run `main.dart` (or `flutter run`).
The app talks to the backend at `http://10.0.2.2:8000` (set in `lib/services/api_service.dart`).
10.0.2.2 is the emulator's alias for your computer's localhost.

## 2. End-to-end check (5 minutes)
1. Get Started > Sign up > you land on Home (0 XP, 1 day streak).
2. Lab: drag H on q0, CNOT on q0 (next column), tap Simulate > bar chart shows |00> and |11> ~50%.
3. Lab: name it, tap Save > Home shows it under Recent circuits > tap it to reload into the Lab.
4. Lab: tap `{ }` > Qiskit code > Copy.
5. Lab: long-press the "q0" label > Bloch sheet (shorter vector = entangled).
6. Learn > Meet the qubit > place X, Check, answer quiz, Complete > +5 XP, ring on Home grows.
7. Arena > The Coin Flip > H > Submit > confetti + XP. Submit a wrong circuit to see a hint.

## 3. Troubleshooting

### Backend
| Problem | Fix |
|---|---|
| `command not found: uvicorn` | `source venv/bin/activate`, or `python -m uvicorn main:app --reload` |
| `no matches found: fastapi[standard]` (zsh) | Quote it, or use `pip install -r requirements.txt` |
| `ModuleNotFoundError: qiskit_aer` / install fails | venv not active, or Python too new: use 3.11/3.12 |
| `Could not import module "main"` | Run uvicorn inside `backend/` |
| `Address already in use` | `--port 8001` (then change kBaseUrl) or `lsof -ti:8000 \| xargs kill` |
| `no such column` / `no such table` | `create_all` never alters tables. Delete `qubitlab.db`, restart |
| Challenges or lessons empty | Seeding only runs on empty tables. Delete `qubitlab.db`, restart |
| 422 error | Read `detail`: usually CNOT without `control`, or qubit index out of range |
| 401 on login / 409 on sign up | Wrong password / username already taken |
| Want to reset XP, streak, progress | Delete `qubitlab.db`, restart |
| `"01"` looks reversed | Qiskit puts q0 on the right: "01" means q0=1, q1=0 |
| Probabilities not exactly 0.5 | Normal shot noise (1024 shots). Arena allows +/-0.05 |

### Flutter / Android
| Problem | Fix |
|---|---|
| "Cannot reach the server at http://10.0.2.2:8000" | 1) Is uvicorn running? 2) Open Chrome inside the emulator and visit `http://10.0.2.2:8000/docs`. If it loads, check the manifest below. If it doesn't, fix the server or firewall (allow Python through the macOS/Windows firewall). |
| `Cleartext HTTP traffic not permitted` | Add `android:usesCleartextTraffic="true"` + INTERNET permission to the manifest (see above), then fully stop and re-run (not hot reload). |
| Physical phone instead of emulator | `uvicorn main:app --host 0.0.0.0`, phone on same Wi-Fi, set `kBaseUrl` to `http://<your-computer-LAN-IP>:8000`. |
| `flutter doctor` shows Android issues | `flutter doctor --android-licenses`, install SDK Platform + Command-line Tools in Android Studio SDK Manager. |
| Gradle / Kotlin / JDK build errors | `flutter clean && flutter pub get`; update Android Studio; use the bundled JDK (Settings > Build Tools > Gradle). |
| `minSdkVersion` error (video player) | In `android/app/build.gradle(.kts)` set `minSdk = 21` (or higher). |
| Emulator very slow / won't start | Use an x86_64 image with hardware acceleration (HAXM/Hyper-V/Hypervisor), 2+ GB RAM, cold boot once. |
| Fonts look plain | google_fonts downloads Poppins on first run; emulator needs internet. Plain font is harmless. |
| Compile errors after paste | `flutter analyze`, fix the first error first. Check the `lib/` folder replaced the default one and `test/widget_test.dart` is deleted. |
| Changes not showing | Provider/const data needs Hot Restart (not Hot Reload). |
| Drag and drop feels dead | In the emulator use click-and-drag with the mouse. Long-press = click and hold ~0.2 s. Drop only works on a wire slot. |
| Slot turns red | Slot occupied, or CNOT/CZ needs 2 free wires in that column. |
| Video shows a placeholder | Paste a YouTube ID into `lib/data/lessons_data.dart` (`youtubeId`). If the player is blank, use an emulator image **with Google Play** or test on a real phone. |
| Session lost on restart | The server must be reachable at start to restore the login. Otherwise just log in again. |
| Lesson "Complete" stays disabled | Needs both: Check circuit succeeds AND the correct quiz answer. |

## 4. Viva talking points
- Backend-first design: the JSON contract (`qubits`, `gates[]`) is validated by Pydantic and used by every screen.
- SQLite + SQLAlchemy `JSON` column: stored as TEXT, auto-serialized by the ORM.
- `CircuitProvider` (Provider/ChangeNotifier): one source of truth; the Lab uses a global instance, lessons/challenges create local ones. Only widgets that watch it rebuild.
- Custom UI: `Draggable` / `DragTarget` grid, `CustomPainter` for wires and the Bloch vector, bottom sheets for results and inspector.
- Rule-based hints (no AI) in `backend/hints.py`; +/-0.05 tolerance for sampling noise.
- One-way translator: visual circuit > Qiskit code (`toQiskitCode()`).

## 5. Known limits
- Bernstein-Vazirani is not included; the Algorithms module has Deutsch-Jozsa (1 bit) and Grover (2 qubits).
- Lesson videos need your own YouTube IDs.
- Auth is simple (salted PBKDF2, user id sent by the client). Fine for a lab project, not production.
