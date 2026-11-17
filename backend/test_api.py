"""Run: python test_api.py   (smoke test for the whole backend)"""
import uuid
from fastapi.testclient import TestClient
from main import app

H0 = {"type": "H", "target": 0}
bell = [H0, {"type": "CNOT", "control": 0, "target": 1}]

with TestClient(app) as c:
    r = c.post("/simulate", json={"qubits": 2, "gates": bell}).json()["results"]
    assert set(r) == {"00", "11"}; print("Bell        :", r)

    # Grover (2 qubits) must give 100% |11>
    g = [{"type": t, "target": q} for t, q in [("H",0),("H",1)]]
    g += [{"type": "CZ", "control": 0, "target": 1}]
    g += [{"type": t, "target": q} for t, q in [("H",0),("H",1),("X",0),("X",1)]]
    g += [{"type": "CZ", "control": 0, "target": 1}]
    g += [{"type": t, "target": q} for t, q in [("X",0),("X",1),("H",0),("H",1)]]
    r = c.post("/simulate", json={"qubits": 2, "gates": g}).json()["results"]
    assert r == {"11": 1.0}; print("Grover      :", r)

    # Deutsch-Jozsa 1-bit balanced oracle: H, Z, H -> |1>
    dj = [{"type": "H", "target": 0}, {"type": "Z", "target": 0}, {"type": "H", "target": 0}]
    r = c.post("/simulate", json={"qubits": 1, "gates": dj}).json()["results"]
    assert r == {"1": 1.0}; print("Deutsch-Jozsa:", r)

    b = c.post("/bloch", json={"qubits": 2, "gates": [H0]}).json()["vectors"]
    print("Bloch H     :", b)
    assert abs(b[0]["x"] - 1) < 1e-3 and abs(b[1]["z"] - 1) < 1e-3
    b = c.post("/bloch", json={"qubits": 2, "gates": bell}).json()["vectors"]
    assert all(abs(v["x"]) + abs(v["y"]) + abs(v["z"]) < 1e-3 for v in b)
    print("Bloch Bell  : both vectors ~0 (entangled)")

    name = "user_" + uuid.uuid4().hex[:6]
    u = c.post("/users/register", json={"username": name, "password": "secret"}).json()
    assert c.post("/users/login", json={"username": name, "password": "bad!!"}).status_code == 401
    u = c.post("/users/login", json={"username": name, "password": "secret"}).json()
    assert u["streak_days"] == 1; print("Login/streak:", u)

    uid = u["id"]
    ch = c.get("/challenges").json()
    assert len(ch) == 5
    # fail with a hint
    r = c.post("/challenges/3/submit", json={"user_id": uid, "qubits": 2, "gates": [H0]}).json()
    assert not r["passed"]; print("Fail hint   :", r["hint"])
    # pass, XP only once
    r = c.post("/challenges/3/submit", json={"user_id": uid, "qubits": 2, "gates": bell}).json()
    assert r["passed"] and r["xp_awarded"] == 20
    r = c.post("/challenges/3/submit", json={"user_id": uid, "qubits": 2, "gates": bell}).json()
    assert r["passed"] and r["xp_awarded"] == 0
    # exact-gates rule
    r = c.post("/challenges/2/submit", json={"user_id": uid, "qubits": 1, "gates": [{"type":"X","target":0}]}).json()
    assert not r["passed"]; print("Exact gates :", r["hint"])

    c.post("/lessons/1/complete", json={"user_id": uid})
    c.post("/lessons/1/complete", json={"user_id": uid})
    me = c.get(f"/users/{uid}").json()
    assert me["xp"] == 25, me
    print("Progress    :", c.get(f"/progress/{uid}").json(), "XP", me["xp"])

    c.post("/circuits/save", json={"user_id": uid, "name": "Bell", "qubits": 2, "circuit_json": bell})
    assert c.get(f"/circuits/{uid}").json()[0]["circuit_json"] == bell
    print("\nALL BACKEND TESTS PASSED")
