import logging
import os

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.auth import get_current_user
from app.config import settings
from app.dependencies import get_school_id
from app.errors import register_exception_handlers
from app.middleware import RateLimitMiddleware, RequestLoggingMiddleware
from app.routers import classrooms, courses, schedule_runs, schedules
from app.routers import school_memberships, teacher_courses, teachers


logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s | %(levelname)-5s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("schedule_api")


app = FastAPI(
    title="Ders Programi Olusturucu",
    description="Okul idarecileri icin otomatik haftalik ders programi olusturma sistemi",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)


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


app.add_middleware(RateLimitMiddleware, max_requests=settings.RATE_LIMIT_PER_MINUTE)
app.add_middleware(RequestLoggingMiddleware)


register_exception_handlers(app)


FILES_DIR = os.path.realpath(
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "files")
)
os.makedirs(FILES_DIR, exist_ok=True)


app.include_router(teachers.router, prefix="/api/v1/teachers", tags=["Ogretmenler"])
app.include_router(classrooms.router, prefix="/api/v1/classrooms", tags=["Siniflar"])
app.include_router(courses.router, prefix="/api/v1/courses", tags=["Dersler"])
app.include_router(
    teacher_courses.router,
    prefix="/api/v1/teacher-courses",
    tags=["Ogretmen-Ders Eslesme"],
)
app.include_router(schedules.router, prefix="/api/v1/schedules", tags=["Ders Programi"])
app.include_router(
    schedule_runs.router,
    prefix="/api/v1/schedule-runs",
    tags=["Program Versiyonlari"],
)
app.include_router(
    school_memberships.router,
    prefix="/api/v1/school-memberships",
    tags=["Okul Uyelikleri"],
)


@app.get("/files/{school_id}/{run_id}/{filename}", tags=["Dosyalar"])
def get_file(
    school_id: int,
    run_id: int,
    filename: str,
    current_user: dict = Depends(get_current_user),
    authorized_school_id: int = Depends(get_school_id),
):
    if school_id != authorized_school_id:
        raise HTTPException(status_code=403, detail="Bu okula ait dosyalara erisim yetkiniz yok")

    if ".." in filename or "/" in filename or "\\" in filename or "\x00" in filename:
        raise HTTPException(status_code=400, detail="Gecersiz dosya adi")

    filepath = os.path.realpath(
        os.path.join(FILES_DIR, str(school_id), str(run_id), filename)
    )

    if not filepath.startswith(FILES_DIR + os.sep) and filepath != FILES_DIR:
        raise HTTPException(status_code=403, detail="Erisim engellendi")

    if not os.path.isfile(filepath):
        raise HTTPException(status_code=404, detail="Dosya bulunamadi")

    return FileResponse(filepath, media_type="application/pdf", filename=filename)


@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "ok",
        "version": "2.0.0",
        "environment": settings.APP_ENV,
    }


@app.get("/", tags=["System"])
def root():
    return {
        "message": "Ders Programi Olusturucu API",
        "version": "2.0.0",
        "docs": "/docs",
    }


@app.on_event("startup")
async def startup_event():
    logger.info("=" * 60)
    logger.info("Ders Programi API baslatiliyor...")
    logger.info("Environment: %s", settings.APP_ENV)
    logger.info("CORS Origins: %s", settings.cors_origin_list)
    logger.info("Rate Limit: %d req/min", settings.RATE_LIMIT_PER_MINUTE)
    logger.info("Docs: enabled")
    logger.info("=" * 60)


if settings.cors_origin_list == ["*"]:
    app = CORSMiddleware(
        app,
        allow_origin_regex=r"https?://.*",
        **cors_kwargs,
    )
else:
    app = CORSMiddleware(
        app,
        allow_origins=settings.cors_origin_list,
        **cors_kwargs,
    )
