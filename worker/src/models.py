from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.sql import func
from .database import Base


class User(Base):
    __tablename__ = "users"

    id            = Column(String(36), primary_key=True)
    email         = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name          = Column(String(255), nullable=False)
    profile_type  = Column(String(50), default="general")
    created_at    = Column(DateTime, server_default=func.now())


class Entry(Base):
    __tablename__ = "entries"

    id           = Column(String(36), primary_key=True)
    user_id      = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    type         = Column(String(20), nullable=False)
    title        = Column(String(500), nullable=False)
    description  = Column(Text, nullable=True)
    status       = Column(String(20), default="pending")
    priority     = Column(String(10), default="normal")
    due_date     = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    created_at   = Column(DateTime, server_default=func.now())
    updated_at   = Column(DateTime, server_default=func.now())
