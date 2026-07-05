# ─── Notevate Backend — FastAPI + Python 3.11 ─────────────────────────────────
# Base: python:3.11-slim (Debian slim, necesario para pymssql/FreeTDS)

FROM python:3.11-slim AS builder
WORKDIR /build

# Dependencias del sistema para pymssql (driver FreeTDS para Azure SQL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    freetds-dev freetds-bin gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ─── Imagen de producción (sin herramientas de build) ─────────────────────────
FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    freetds-bin curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

COPY ./src ./src

# Usuario no-root por seguridad
RUN addgroup --system notevate && adduser --system --ingroup notevate notevate
USER notevate

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=2 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
