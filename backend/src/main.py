from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import os

from .database import engine, Base
from .routers import users, entries

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        # Crear tablas en la base de datos usando SQLAlchemy
        Base.metadata.create_all(bind=engine)

        # Log de éxito
        logger.info("✅ Conexión a Azure SQL OK — tablas inicializadas")

    except Exception as e:
        # Captura cualquier error (credenciales, red, firewall, etc.)
        logger.error(f"❌ Error al conectar/inicializar DB: {e}")

        # IMPORTANTE:
        # No hacemos raise → la app sigue viva para ECS/ALB
        # Esto permite debuggear sin que el contenedor entre en crash loop

    # Continúa ejecución normal de FastAPI
    yield


app = FastAPI(
    title="Notevate API",
    description="API REST para la plataforma de productividad personal Notevate",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── HEALTH CHECK (requerido por el ALB de AWS) ────────────────────────────────
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "notevate-backend",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "azure_sql_server": os.getenv("AZURE_SQL_SERVER", "not-configured"),
    }


app.include_router(users.router, prefix="/api/users", tags=["Usuarios"])
app.include_router(entries.router, prefix="/api/entries", tags=["Entradas"])
# Pipeline Test
