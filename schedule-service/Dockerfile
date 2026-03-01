# ──────────────────────────────────────────────────────────────────────────────
# Stage 1: Builder — install dependencies
# ──────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Requirements önce kopyalanır → layer cache optimizasyonu
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ──────────────────────────────────────────────────────────────────────────────
# Stage 2: Runtime — production image
# ──────────────────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Builder'dan sadece kurulu paketleri kopyala
COPY --from=builder /install /usr/local

# Non-root user oluştur
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

# Uygulama kodunu kopyala
COPY . .

# files klasörünü oluştur ve yetkiyi ver
RUN mkdir -p /app/files && chown -R appuser:appuser /app

# Non-root user'a geç
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
