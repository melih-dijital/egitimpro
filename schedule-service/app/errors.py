"""
Standart hata response'ları ve global exception handler.

Tüm hata mesajları aynı formatta döner:
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Kullanıcı dostu mesaj",
    "details": {}  // opsiyonel ek bilgiler
  }
}
"""

import logging
import traceback

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError

from app.config import settings

logger = logging.getLogger("schedule_api")


# ─── Error Codes ──────────────────────────────────────────────────────────────

class ErrorCode:
    UNAUTHORIZED = "UNAUTHORIZED"
    FORBIDDEN = "FORBIDDEN"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    VALIDATION_ERROR = "VALIDATION_ERROR"
    RATE_LIMITED = "RATE_LIMITED"
    UNPROCESSABLE = "UNPROCESSABLE"
    FILE_TOO_LARGE = "FILE_TOO_LARGE"
    SERVER_ERROR = "INTERNAL_SERVER_ERROR"
    SCHEDULE_FAILED = "SCHEDULE_FAILED"
    BAD_REQUEST = "BAD_REQUEST"


def _error_response(status_code: int, code: str, message: str, details: dict | None = None) -> JSONResponse:
    body = {
        "error": {
            "code": code,
            "message": message,
        }
    }
    if details:
        body["error"]["details"] = details
    return JSONResponse(status_code=status_code, content=body)


# ─── Register Handlers ───────────────────────────────────────────────────────

def register_exception_handlers(app: FastAPI) -> None:
    """FastAPI uygulamasına tüm global exception handler'ları ekler."""

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        """HTTPException'ları standart formata çevir."""
        code_map = {
            400: ErrorCode.BAD_REQUEST,
            401: ErrorCode.UNAUTHORIZED,
            403: ErrorCode.FORBIDDEN,
            404: ErrorCode.NOT_FOUND,
            409: ErrorCode.CONFLICT,
            413: ErrorCode.FILE_TOO_LARGE,
            422: ErrorCode.UNPROCESSABLE,
            429: ErrorCode.RATE_LIMITED,
        }
        error_code = code_map.get(exc.status_code, ErrorCode.SERVER_ERROR)
        return _error_response(exc.status_code, error_code, str(exc.detail))

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        """Pydantic validasyon hatalarını kullanıcı dostu formata çevir."""
        errors = []
        for err in exc.errors():
            field = " → ".join(str(loc) for loc in err.get("loc", []))
            errors.append({
                "field": field,
                "message": err.get("msg", ""),
                "type": err.get("type", ""),
            })

        return _error_response(
            422,
            ErrorCode.VALIDATION_ERROR,
            "İstek doğrulama hatası. Lütfen gönderilen verileri kontrol edin.",
            {"fields": errors},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        """Beklenmeyen hataları yakala, logla, güvenli mesaj döndür."""
        logger.error(
            "UNHANDLED_ERROR | %s %s | error=%s\n%s",
            request.method,
            request.url.path,
            str(exc)[:300],
            traceback.format_exc() if settings.DEBUG else "",
        )

        # Production'da stack trace'i kullanıcıya gösterme
        message = (
            f"Sunucu hatası: {str(exc)}"
            if settings.DEBUG
            else "Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin."
        )

        return _error_response(500, ErrorCode.SERVER_ERROR, message)
