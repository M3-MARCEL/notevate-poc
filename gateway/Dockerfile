FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./src ./src
RUN addgroup --system notevate && \
    adduser --system --ingroup notevate notevate
USER notevate
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=2 \
CMD curl -f http://localhost:8080/health || exit 1
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
