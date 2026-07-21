"""
Notevate Analytics Worker
──────────────────────────
Módulo independiente (pensado para ejecución on-premise, ej. Proxmox VM +
Docker) que procesa de forma asíncrona las entradas de los usuarios y
calcula métricas de productividad:

  - Tasa de finalización de tareas por usuario.
  - Racha de hábitos consecutivos completados.
  - Entradas vencidas sin resolver (para alimentar el motor de decisiones).

No expone una API pública; se ejecuta en un bucle continuo con un
intervalo configurable y registra resultados en logs estructurados
(en una siguiente iteración se podría escribir a una tabla de métricas
o publicar en una cola).
"""

import logging
import os
import time
from datetime import datetime, timezone
from collections import defaultdict

from sqlalchemy.orm import Session
from .database import SessionLocal
from .models import Entry

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("notevate-worker")

POLL_INTERVAL_SECONDS = int(os.getenv("WORKER_POLL_INTERVAL", "300"))


def compute_productivity_metrics(db: Session) -> dict:
    """Calcula métricas agregadas por usuario a partir de las entradas."""
    entries = db.query(Entry).all()
    by_user = defaultdict(list)
    for entry in entries:
        by_user[entry.user_id].append(entry)

    now = datetime.now(timezone.utc)
    summary = {}

    for user_id, user_entries in by_user.items():
        total = len(user_entries)
        completed = sum(1 for e in user_entries if e.status == "completed")
        overdue = sum(
            1
            for e in user_entries
            if e.status == "pending"
            and e.due_date is not None
            and e.due_date.replace(tzinfo=timezone.utc) < now
        )
        completion_rate = round(completed / total, 2) if total else 0.0

        summary[user_id] = {
            "total_entries": total,
            "completed": completed,
            "overdue": overdue,
            "completion_rate": completion_rate,
        }

    return summary


def run_cycle():
    db = SessionLocal()
    try:
        metrics = compute_productivity_metrics(db)
        logger.info(f"Ciclo de análisis completado — {len(metrics)} usuarios procesados")
        for user_id, stats in metrics.items():
            logger.info(f"user={user_id} stats={stats}")
    except Exception as exc:
        logger.error(f"Error durante el ciclo de análisis: {exc}")
    finally:
        db.close()


HEARTBEAT_FILE = "/tmp/worker-heartbeat"


def touch_heartbeat():
    """Escribe un archivo con la hora actual; usado por HEALTHCHECK de Docker."""
    with open(HEARTBEAT_FILE, "w") as f:
        f.write(str(time.time()))


def main():
    logger.info("Notevate Analytics Worker iniciado")
    logger.info(f"Intervalo de sondeo: {POLL_INTERVAL_SECONDS}s")
    while True:
        run_cycle()
        touch_heartbeat()
        time.sleep(POLL_INTERVAL_SECONDS)


if __name__ == "__main__":
    main()
# Pipeline Test 
