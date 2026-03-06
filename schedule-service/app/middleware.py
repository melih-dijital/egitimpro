"""
Production middleware: request logging, rate limiting, error standardization.
"""

import time
import logging
from collections import defaultdict

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import settings

logger = logging.getLogger("schedule_api")


# ─── Request Logging Middleware ───────────────────────────────────────────────

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Her request için structured log üretir:
    - Method, path, status code, duration
    - Client IP, User-Agent
    - school_id (varsa)
    """

    async def dispatch(self, request: Request, call_next):
        start_time = time.time()

        # Client bilgileri
        client_ip = request.client.host if request.client else "unknown"
        user_agent = request.headers.get("user-agent", "")[:100]
        school_id = request.headers.get("x-school-id", "-")

        try:
            response = await call_next(request)
        except Exception as exc:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(
                "REQUEST_ERROR | %s %s | ip=%s | school=%s | %.0fms | error=%s",
                request.method,
                request.url.path,
                client_ip,
                school_id,
                duration_ms,
                str(exc)[:200],
            )
            raise

        duration_ms = (time.time() - start_time) * 1000

        # Health check'leri loglamaya gerek yok
        if request.url.path not in ("/health", "/"):
            log_fn = logger.warning if response.status_code >= 400 else logger.info
            log_fn(
                "%s %s | %d | ip=%s | school=%s | %.0fms | ua=%s",
                request.method,
                request.url.path,
                response.status_code,
                client_ip,
                school_id,
                duration_ms,
                user_agent[:50],
            )

        # Response header'lara timing ekle
        response.headers["X-Process-Time-Ms"] = f"{duration_ms:.0f}"

        return response


# ─── Rate Limiting Middleware ─────────────────────────────────────────────────

class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    IP bazlı basit rate limiter.
    Sliding window: dakikada RATE_LIMIT_PER_MINUTE request.
    Limit aşılırsa 429 döner.
    """

    def __init__(self, app, max_requests: int = 60):
        super().__init__(app)
        self.max_requests = max_requests
        # {ip: [timestamp, timestamp, ...]}
        self._requests: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        # Health check ve root rate limit'e tabi olmasın
        if request.url.path in ("/health", "/"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.time()
        window_start = now - 60  # 1 dakikalık pencere

        # Eski kayıtları temizle
        self._requests[client_ip] = [
            t for t in self._requests[client_ip] if t > window_start
        ]

        if len(self._requests[client_ip]) >= self.max_requests:
            remaining = 0
            retry_after = int(self._requests[client_ip][0] + 60 - now) + 1
            logger.warning(
                "RATE_LIMIT | ip=%s | path=%s | limit=%d/min",
                client_ip, request.url.path, self.max_requests,
            )
            return Response(
                content='{"error": {"code": "RATE_LIMITED", "message": "Çok fazla istek. Lütfen biraz bekleyin."}}',
                status_code=429,
                media_type="application/json",
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(self.max_requests),
                    "X-RateLimit-Remaining": str(remaining),
                },
            )

        self._requests[client_ip].append(now)
        remaining = self.max_requests - len(self._requests[client_ip])

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(self.max_requests)
        response.headers["X-RateLimit-Remaining"] = str(remaining)

        return response
