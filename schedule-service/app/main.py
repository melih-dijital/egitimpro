from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

import os

from app.config import settings
from app.routers import teachers, classrooms, courses, teacher_courses, schedules

app = FastAPI(
    title="Ders Programı Oluşturucu",
    description="Okul idarecileri için otomatik haftalık ders programı oluşturma sistemi",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Files directory
FILES_DIR = os.path.realpath(os.path.join(os.path.dirname(os.path.dirname(__file__)), "files"))
os.makedirs(FILES_DIR, exist_ok=True)

# Include routers
app.include_router(teachers.router, prefix="/api/v1/teachers", tags=["Öğretmenler"])
app.include_router(classrooms.router, prefix="/api/v1/classrooms", tags=["Sınıflar"])
app.include_router(courses.router, prefix="/api/v1/courses", tags=["Dersler"])
app.include_router(teacher_courses.router, prefix="/api/v1/teacher-courses", tags=["Öğretmen-Ders Eşleştirme"])
app.include_router(schedules.router, prefix="/api/v1/schedules", tags=["Ders Programı"])


# ─── Secure File Serving ─────────────────────────────────────────────────────

@app.get("/files/{filename}", tags=["Dosyalar"])
def get_file(filename: str):
    """
    PDF dosyalarını güvenli şekilde servis eder.

    - Path traversal saldırılarını engeller
    - Sadece /app/files klasörü içinden dosya sunar
    - Dosya yoksa 404 döner
    """
    # Path traversal koruması
    if ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Geçersiz dosya adı")

    if "\x00" in filename:
        raise HTTPException(status_code=400, detail="Geçersiz dosya adı")

    # Dosya yolunu oluştur ve doğrula
    filepath = os.path.realpath(os.path.join(FILES_DIR, filename))

    # Resolved path FILES_DIR içinde mi kontrol et
    if not filepath.startswith(FILES_DIR + os.sep) and filepath != FILES_DIR:
        raise HTTPException(status_code=403, detail="Erişim engellendi")

    if not os.path.isfile(filepath):
        raise HTTPException(status_code=404, detail="Dosya bulunamadı")

    return FileResponse(
        filepath,
        media_type="application/pdf",
        filename=filename,
    )


# ─── System ──────────────────────────────────────────────────────────────────

@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok"}


@app.get("/", tags=["System"])
def root():
    return {
        "message": "Ders Programı Oluşturucu API",
        "docs": "/docs",
        "version": "1.0.0",
    }

