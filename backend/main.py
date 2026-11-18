import hashlib
import hmac
import os
from contextlib import asynccontextmanager
from datetime import date, timedelta

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import models
import quantum
import schemas
from database import Base, SessionLocal, engine, get_db
from hints import make_hint
from seed import seed_all

LESSON_XP = 5


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_all(db)
    yield


app = FastAPI(title="QubitLab API", version="1.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


# ---------- helpers ----------
def hash_password(password: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 100_000)
    return salt.hex() + "$" + digest.hex()


def verify_password(password: str, stored: str) -> bool:
    salt_hex, digest_hex = stored.split("$")
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), bytes.fromhex(salt_hex), 100_000)
    return hmac.compare_digest(digest.hex(), digest_hex)


def touch_streak(user: models.User):
    today = date.today()
    if user.last_active_date == today:
        return
    if user.last_active_date == today - timedelta(days=1):
        user.streak_days = (user.streak_days or 0) + 1
    else:
        user.streak_days = 1
    user.last_active_date = today


def matches(target: dict, results: dict, tol: float = 0.05) -> bool:
    return all(abs(target.get(k, 0.0) - results.get(k, 0.0)) <= tol
               for k in set(target) | set(results))


def get_user_or_404(db: Session, user_id: int) -> models.User:
    user = db.get(models.User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return user


# ---------- quantum ----------
@app.post("/simulate", response_model=schemas.SimulateResponse)
def simulate(req: schemas.CircuitRequest):
    return {
        "results": quantum.simulate(req),
        "bloch_vectors": quantum.bloch_vectors(req),
    }


@app.post("/bloch", response_model=schemas.BlochOut)
def bloch(req: schemas.CircuitRequest):
    return {"vectors": quantum.bloch_vectors(req)}


# ---------- users ----------
@app.post("/users/register", response_model=schemas.UserOut, status_code=201)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if db.query(models.User).filter_by(username=user.username).first():
        raise HTTPException(409, "Username already taken")
    db_user = models.User(username=user.username, password_hash=hash_password(user.password))
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.post("/users/login", response_model=schemas.UserOut)
def login(body: schemas.UserCreate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter_by(username=body.username).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Wrong username or password")
    touch_streak(user)
    db.commit()
    db.refresh(user)
    return user


@app.get("/users/{user_id}", response_model=schemas.UserOut)
def get_user(user_id: int, db: Session = Depends(get_db)):
    return get_user_or_404(db, user_id)


@app.get("/progress/{user_id}", response_model=schemas.ProgressOut)
def progress(user_id: int, db: Session = Depends(get_db)):
    get_user_or_404(db, user_id)
    lessons = db.query(models.LessonProgress.lesson_id).filter_by(user_id=user_id).all()
    chals = db.query(models.ChallengeCompletion.challenge_id).filter_by(user_id=user_id).all()
    return {"completed_lessons": [r[0] for r in lessons],
            "completed_challenges": [r[0] for r in chals]}


# ---------- circuits ----------
@app.post("/circuits/save", response_model=schemas.CircuitOut, status_code=201)
def save_circuit(body: schemas.CircuitSave, db: Session = Depends(get_db)):
    get_user_or_404(db, body.user_id)
    circuit = models.SavedCircuit(**body.model_dump())
    db.add(circuit)
    db.commit()
    db.refresh(circuit)
    return circuit


@app.get("/circuits/{user_id}", response_model=list[schemas.CircuitOut])
def list_circuits(user_id: int, db: Session = Depends(get_db)):
    return (db.query(models.SavedCircuit).filter_by(user_id=user_id)
            .order_by(models.SavedCircuit.created_at.desc()).all())


# ---------- lessons ----------
@app.get("/lessons", response_model=list[schemas.LessonOut])
def list_lessons(db: Session = Depends(get_db)):
    return db.query(models.Lesson).order_by(models.Lesson.order_index).all()


@app.post("/lessons/{lesson_id}/complete", response_model=schemas.UserOut)
def complete_lesson(lesson_id: int, body: schemas.LessonComplete, db: Session = Depends(get_db)):
    user = get_user_or_404(db, body.user_id)
    if not db.get(models.Lesson, lesson_id):
        raise HTTPException(404, "Lesson not found")
    done = db.query(models.LessonProgress).filter_by(user_id=user.id, lesson_id=lesson_id).first()
    if not done:
        db.add(models.LessonProgress(user_id=user.id, lesson_id=lesson_id))
        user.xp = (user.xp or 0) + LESSON_XP
    touch_streak(user)
    db.commit()
    db.refresh(user)
    return user


# ---------- challenges ----------
@app.get("/challenges", response_model=list[schemas.ChallengeOut])
def list_challenges(db: Session = Depends(get_db)):
    return db.query(models.Challenge).order_by(models.Challenge.id).all()


@app.post("/challenges/{challenge_id}/submit", response_model=schemas.SubmitResult)
def submit_challenge(challenge_id: int, body: schemas.SubmitBody, db: Session = Depends(get_db)):
    ch = db.get(models.Challenge, challenge_id)
    if not ch:
        raise HTTPException(404, "Challenge not found")
    user = get_user_or_404(db, body.user_id)

    req = schemas.CircuitRequest(qubits=body.qubits, gates=body.gates)
    results = quantum.simulate(req)
    passed = matches(ch.target_json_state, results) and (
        ch.exact_gates is None or len(body.gates) == ch.exact_gates)

    xp = 0
    if passed:
        already = db.query(models.ChallengeCompletion).filter_by(
            user_id=user.id, challenge_id=ch.id).first()
        if not already:
            db.add(models.ChallengeCompletion(user_id=user.id, challenge_id=ch.id))
            user.xp = (user.xp or 0) + ch.xp_reward
            xp = ch.xp_reward
    touch_streak(user)
    db.commit()

    return {
        "passed": passed,
        "results": results,
        "target": ch.target_json_state,
        "xp_awarded": xp,
        "hint": None if passed else make_hint(ch.target_json_state, body.gates, results, ch.exact_gates),
    }
