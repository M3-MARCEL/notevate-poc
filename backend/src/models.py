from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import uuid

class User(Base):
    __tablename__ = "users"

    id            = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email         = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name          = Column(String(255), nullable=False)
    profile_type  = Column(String(50), default="general")
    created_at    = Column(DateTime, server_default=func.now())

    entries = relationship("Entry", back_populates="user", cascade="all, delete-orphan")


class Entry(Base):
    __tablename__ = "entries"

    id           = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id      = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    type         = Column(String(20), nullable=False)   # task/habit/project/idea/event
    title        = Column(String(500), nullable=False)
    description  = Column(Text, nullable=True)
    status       = Column(String(20), default="pending")  # pending/completed/discarded/rescheduled
    priority     = Column(String(10), default="normal")   # low/normal/high
    due_date     = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    created_at   = Column(DateTime, server_default=func.now())
    updated_at   = Column(DateTime, server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="entries")
