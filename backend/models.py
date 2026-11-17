from datetime import datetime, timezone
from sqlalchemy import (Column, Integer, String, JSON, DateTime, Date, ForeignKey,
                        Text, UniqueConstraint)

from database import Base


def _now():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    xp = Column(Integer, default=0)
    streak_days = Column(Integer, default=0)
    last_active_date = Column(Date, nullable=True)


class Lesson(Base):
    __tablename__ = "lessons"
    id = Column(Integer, primary_key=True)
    module_name = Column(String, nullable=False)
    title = Column(String, nullable=False)
    video_url = Column(String)
    order_index = Column(Integer, default=0)


class LessonProgress(Base):
    __tablename__ = "lesson_progress"
    __table_args__ = (UniqueConstraint("user_id", "lesson_id"),)
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completed_at = Column(DateTime, default=_now)


class Challenge(Base):
    __tablename__ = "challenges"
    id = Column(Integer, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    qubits = Column(Integer, default=2)
    target_json_state = Column(JSON, nullable=False)
    xp_reward = Column(Integer, default=10)
    exact_gates = Column(Integer, nullable=True)  # e.g. "exactly two gates"


class ChallengeCompletion(Base):
    __tablename__ = "challenge_completions"
    __table_args__ = (UniqueConstraint("user_id", "challenge_id"),)
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    challenge_id = Column(Integer, ForeignKey("challenges.id"), nullable=False)
    completed_at = Column(DateTime, default=_now)


class SavedCircuit(Base):
    __tablename__ = "saved_circuits"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, index=True)
    qubits = Column(Integer, default=2)
    circuit_json = Column(JSON)
    created_at = Column(DateTime, default=_now)
