from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import Optional, List
from ..database import get_db
from ..models import User, Entry
from ..schemas import EntryCreate, EntryUpdate, EntryDecision, EntryResponse
from ..auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[EntryResponse])
def list_entries(type: Optional[str] = None, status: Optional[str] = None,
                 db: Session = Depends(get_db),
                 current_user: User = Depends(get_current_user)):
    q = db.query(Entry).filter(Entry.user_id == current_user.id)
    if type:   q = q.filter(Entry.type == type)
    if status: q = q.filter(Entry.status == status)
    return q.order_by(Entry.created_at.desc()).all()

@router.post("/", response_model=EntryResponse, status_code=201)
def create_entry(data: EntryCreate, db: Session = Depends(get_db),
                 current_user: User = Depends(get_current_user)):
    entry = Entry(user_id=current_user.id, **data.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{entry_id}", response_model=EntryResponse)
def update_entry(entry_id: str, data: EntryUpdate,
                 db: Session = Depends(get_db),
                 current_user: User = Depends(get_current_user)):
    entry = db.query(Entry).filter(Entry.id == entry_id,
                                   Entry.user_id == current_user.id).first()
    if not entry:
        raise HTTPException(404, "Entrada no encontrada")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(entry, k, v)
    if data.status == "completed":
        entry.completed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
def delete_entry(entry_id: str, db: Session = Depends(get_db),
                 current_user: User = Depends(get_current_user)):
    entry = db.query(Entry).filter(Entry.id == entry_id,
                                   Entry.user_id == current_user.id).first()
    if not entry:
        raise HTTPException(404, "Entrada no encontrada")
    db.delete(entry)
    db.commit()


# ─── MOTOR DE DECISIONES ──────────────────────────────────────────────────────
@router.get("/overdue", response_model=List[EntryResponse])
def get_overdue(db: Session = Depends(get_db),
                current_user: User = Depends(get_current_user)):
    """Retorna entradas vencidas pendientes de decisión."""
    now = datetime.now(timezone.utc)
    return db.query(Entry).filter(
        Entry.user_id == current_user.id,
        Entry.due_date < now,
        Entry.status == "pending"
    ).all()


@router.post("/{entry_id}/decision", response_model=EntryResponse)
def apply_decision(entry_id: str, decision: EntryDecision,
                   db: Session = Depends(get_db),
                   current_user: User = Depends(get_current_user)):
    """Motor de decisiones: reagendar, dividir o descartar una entrada vencida."""
    entry = db.query(Entry).filter(Entry.id == entry_id,
                                   Entry.user_id == current_user.id,
                                   Entry.status == "pending").first()
    if not entry:
        raise HTTPException(404, "Entrada no encontrada o ya procesada")

    if decision.action == "reschedule":
        if not decision.new_due_date:
            raise HTTPException(400, "Debe proporcionar nueva fecha")
        entry.due_date = decision.new_due_date
        entry.status = "rescheduled"

    elif decision.action == "split":
        if not decision.subtasks or len(decision.subtasks) < 2:
            raise HTTPException(400, "Debe proporcionar al menos 2 subtareas")
        for title in decision.subtasks:
            db.add(Entry(user_id=current_user.id, type="task",
                         title=title, priority=entry.priority, status="pending"))
        entry.status = "discarded"

    elif decision.action == "discard":
        entry.status = "discarded"

    db.commit()
    db.refresh(entry)
    return entry
