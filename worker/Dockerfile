FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    freetds-dev freetds-bin gcc \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./src ./src
RUN addgroup --system notevate && \
    adduser --system --ingroup notevate notevate
USER notevate
HEALTHCHECK --interval=60s --timeout=5s --start-period=30s --retries=2 \
CMD find /tmp/worker-heartbeat -mmin -6 | grep -q worker-heartbeat || exit 1
CMD ["python", "-m", "src.main"]
