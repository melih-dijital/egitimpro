#!/bin/sh
set -eu

echo "[entrypoint] Running alembic migrations..."
alembic upgrade head

echo "[entrypoint] Starting API..."
exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --workers 4 \
  --timeout-keep-alive 30 \
  --timeout-graceful-shutdown 10 \
  --access-log \
  --log-level info
