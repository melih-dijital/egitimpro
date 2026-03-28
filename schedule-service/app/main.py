import os
import logging

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.config import settings
from app.auth import get_current_user
from app.dependencies import get_school_id
from app.middleware import RequestLoggingMiddleware, RateLimitMiddleware
from app.errors import register_exception_handlers
from app.routers import teachers, classrooms, courses, teacher_courses, schedules
from app.routers import schedule_runs, school_memberships


# ─── Logging Setup ────────────────────────────────────────────────────────────

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s | %(levelname)-5s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("schedule_api")


# ─── App ──────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Ders Programı Oluşturucu",
    description="Okul idarecileri için otomatik haftalık ders programı oluşturma sistemi (Multi-Tenant SaaS)",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)


# ─── Middleware (sıralama önemli: ilk eklenen en dışta çalışır) ───────────────

# 1. CORS — en dışta olmalı ki hata/preflight cevaplarına da header eklensin
cors_kwargs = {
    "allow_credentials": True,
    "allow_methods": ["*"],
    "allow_headers": ["*"],
    "expose_headers": [
        "X-Process-Time-Ms",
        "X-RateLimit-Limit",
        "X-RateLimit-Remaining",
    ],
}
if settings.cors_origin_list == ["*"]:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"https?://.*",
        **cors_kwargs,
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        **cors_kwargs,
    )

# 2. Rate Limiting
app.add_middleware(RateLimitMiddleware, max_requests=settings.RATE_LIMIT_PER_MINUTE)

# 3. Request Logging
app.add_middleware(RequestLoggingMiddleware)


# ─── Exception Handlers ──────────────────────────────────────────────────────

register_exception_handlers(app)


# ─── Files Directory ─────────────────────────────────────────────────────────

FILES_DIR = os.path.realpath(os.path.join(os.path.dirname(os.path.dirname(__file__)), "files"))
os.makedirs(FILES_DIR, exist_ok=True)


# ─── Routers ─────────────────────────────────────────────────────────────────

app.include_router(teachers.router, prefix="/api/v1/teachers", tags=["Öğretmenler"])
app.include_router(classrooms.router, prefix="/api/v1/classrooms", tags=["Sınıflar"])
app.include_router(courses.router, prefix="/api/v1/courses", tags=["Dersler"])
app.include_router(teacher_courses.router, prefix="/api/v1/teacher-courses", tags=["Öğretmen-Ders Eşleştirme"])
app.include_router(schedules.router, prefix="/api/v1/schedules", tags=["Ders Programı"])
app.include_router(schedule_runs.router, prefix="/api/v1/schedule-runs", tags=["Program Versiyonları"])
app.include_router(
    school_memberships.router,
    prefix="/api/v1/school-memberships",
    tags=["Okul Üyelikleri"],
)


# ─── Secure File Serving ─────────────────────────────────────────────────────

@app.get("/files/{school_id}/{run_id}/{filename}", tags=["Dosyalar"])
def get_file(
    school_id: int,
    run_id: int,
    filename: str,
    current_user: dict = Depends(get_current_user),
    authorized_school_id: int = Depends(get_school_id),
):
    """
    PDF dosyalarını güvenli şekilde servis eder.

    - Authorization zorunlu
    - school_id kontrolü yapılır
    - Path traversal koruması
    """
    if school_id != authorized_school_id:
        raise HTTPException(status_code=403, detail="Bu okula ait dosyalara erişim yetkiniz yok")

    if ".." in filename or "/" in filename or "\\" in filename or "\x00" in filename:
        raise HTTPException(status_code=400, detail="Geçersiz dosya adı")

    filepath = os.path.realpath(os.path.join(FILES_DIR, str(school_id), str(run_id), filename))

    if not filepath.startswith(FILES_DIR + os.sep) and filepath != FILES_DIR:
        raise HTTPException(status_code=403, detail="Erişim engellendi")

    if not os.path.isfile(filepath):
        raise HTTPException(status_code=404, detail="Dosya bulunamadı")

    return FileResponse(filepath, media_type="application/pdf", filename=filename)


# ─── System ──────────────────────────────────────────────────────────────────

@app.get("/health", tags=["System"])
def health_check():
    """
    Sistem sağlık kontrolü.
    Load balancer / Docker healthcheck tarafından kullanılır.
    """
    return {
        "status": "ok",
        "version": "2.0.0",
        "environment": settings.APP_ENV,
    }


@app.get("/", tags=["System"])
def root():
    return {
        "message": "Ders Programı Oluşturucu API",
        "version": "2.0.0",
        "docs": "/docs",
    }


# ─── Startup ─────────────────────────────────────────────────────────────────

@app.on_event("startup")
async def startup_event():
    logger.info("=" * 60)
    logger.info("Ders Programı API başlatılıyor...")
    logger.info("Environment: %s", settings.APP_ENV)
    logger.info("CORS Origins: %s", settings.cors_origin_list)
    logger.info("Rate Limit: %d req/min", settings.RATE_LIMIT_PER_MINUTE)
    logger.info("Docs: %s", "enabled")
    logger.info("=" * 60)
