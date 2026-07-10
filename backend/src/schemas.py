from pydantic import BaseModel, EmailStr
from typing import Optional, Literal, List
from datetime import datetime

# ─── USUARIOS ─────────────────────────────────────────────────────────────────


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    profile_type: Literal["estudiante", "profesional", "general"] = "general"


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    profile_type: str
    created_at: datetime
    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ─── ENTRADAS ─────────────────────────────────────────────────────────────────
class EntryCreate(BaseModel):
    type: Literal["task", "habit", "project", "idea", "event"]
    title: str
    description: Optional[str] = None
    priority: Literal["low", "normal", "high"] = "normal"
    due_date: Optional[datetime] = None


class EntryUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[Literal["pending", "completed", "discarded", "rescheduled"]] = None
    priority: Optional[Literal["low", "normal", "high"]] = None
    due_date: Optional[datetime] = None


class EntryDecision(BaseModel):
    action: Literal["reschedule", "split", "discard"]
    new_due_date: Optional[datetime] = None
    subtasks: Optional[List[str]] = None


class EntryResponse(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    description: Optional[str]
    status: str
    priority: str
    due_date: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}
