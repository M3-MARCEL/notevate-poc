"""
Notevate API Gateway
─────────────────────
Módulo independiente que actúa como punto de entrada único para el cliente.
Responsabilidades:
  - Enrutar peticiones hacia el backend (notevate-backend).
  - Validar la presencia de un token antes de reenviar la petición
    (defensa en profundidad; el backend también valida el JWT).
  - Rate limiting básico por IP para mitigar abuso.
  - Exponer /health para el ALB / orquestador.

Este módulo se despliega como contenedor independiente y no comparte
proceso ni dependencias de build con notevate-backend.
"""

from fastapi import FastAPI, Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import httpx
import logging
import os
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BACKEND_URL = os.getenv("BACKEND_URL", "http://notevate-backend:8000")
RATE_LIMIT_WINDOW_SECONDS = 60
RATE_LIMIT_MAX_REQUESTS = 120

# Almacén en memoria simple: {ip: [timestamps]}. Para producción multi-instancia
# esto debería moverse a Redis, pero para el alcance del PoC basta.
_request_log: dict[str, list[float]] = {}


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window_start = now - RATE_LIMIT_WINDOW_SECONDS

        timestamps = _request_log.get(client_ip, [])
        timestamps = [t for t in timestamps if t > window_start]

        if len(timestamps) >= RATE_LIMIT_MAX_REQUESTS:
            logger.warning(f"Rate limit excedido para {client_ip}")
            raise HTTPException(status_code=429, detail="Demasiadas solicitudes")

        timestamps.append(now)
        _request_log[client_ip] = timestamps
        return await call_next(request)


app = FastAPI(
    title="Notevate Gateway",
    description="Puerta de enlace de la plataforma Notevate — enrutamiento y rate limiting",
    version="1.0.0",
)

app.add_middleware(RateLimitMiddleware)


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "notevate-gateway",
        "backend_url": BACKEND_URL,
        "environment": os.getenv("ENVIRONMENT", "development"),
    }


@app.api_route(
    "/api/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
)
async def proxy(path: str, request: Request):
    """Reenvía la petición al backend, preservando método, headers y cuerpo."""
    if request.headers.get("authorization") is None and not path.startswith("users/login"):
        raise HTTPException(status_code=401, detail="Falta encabezado Authorization")

    url = f"{BACKEND_URL}/api/{path}"
    body = await request.body()

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            upstream_response = await client.request(
                method=request.method,
                url=url,
                headers={
                    k: v
                    for k, v in request.headers.items()
                    if k.lower() not in ("host", "content-length")
                },
                content=body,
                params=request.query_params,
            )
        except httpx.RequestError as exc:
            logger.error(f"Error al contactar el backend: {exc}")
            raise HTTPException(status_code=502, detail="Backend no disponible")

    return upstream_response.json() if upstream_response.content else {}


# Pipeline Test
