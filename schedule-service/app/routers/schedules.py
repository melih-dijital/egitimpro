from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.course import Course
from app.models.classroom import Classroom
from app.models.schedule import Schedule
from app.algorithms.scheduler import generate_schedule
from app.services.pdf_generator import generate_classroom_pdf
from app.config import settings

router = APIRouter()


# ─── Generate Schedule ────────────────────────────────────────────────────────

@router.post("/generate-schedule", status_code=201)
def generate(db: Session = Depends(get_db)):
    """
    OR-Tools CP-SAT ile otomatik ders programı oluştur.

    1. Veritabanından öğretmen, ders, sınıf ve eşleştirmeleri çeker
    2. CP-SAT algoritmasını çalıştırır
    3. Sonucu Schedule tablosuna kaydeder
    4. Başarı durumunu JSON olarak döndürür
    """
    try:
        result = generate_schedule(db)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Algoritma çalıştırılırken hata oluştu: {str(e)}",
        )

    if not result.success:
        raise HTTPException(status_code=422, detail=result.message)

    # Mevcut programı temizle ve yenisini kaydet
    db.query(Schedule).delete()

    for entry in result.entries:
        row = Schedule(
            classroom_id=entry["classroom_id"],
            teacher_id=entry["teacher_id"],
            course_id=entry["course_id"],
            day=entry["day"],
            hour=entry["hour"],
        )
        db.add(row)

    db.commit()

    # Sınıf bazlı özet
    classroom_summary: dict[int, int] = {}
    for entry in result.entries:
        cl_id = entry["classroom_id"]
        classroom_summary[cl_id] = classroom_summary.get(cl_id, 0) + 1

    classrooms = db.query(Classroom).filter(Classroom.id.in_(classroom_summary.keys())).all()
    cl_names = {c.id: c.name for c in classrooms}

    return {
        "success": True,
        "message": result.message,
        "total_entries": len(result.entries),
        "classrooms": [
            {"classroom_id": cl_id, "classroom_name": cl_names.get(cl_id, ""), "lesson_count": count}
            for cl_id, count in classroom_summary.items()
        ],
    }


# ─── Generate PDF ─────────────────────────────────────────────────────────────

@router.post("/generate-pdf", status_code=201)
def generate_pdf(
    school_name: str = Query(default="Okul Adı", description="PDF başlığında görünecek okul adı"),
    db: Session = Depends(get_db),
):
    """
    Her sınıf için ayrı PDF oluşturur.

    - Schedule tablosundan mevcut programı okur
    - Her sınıf için ayrı tablo formatında PDF üretir
    - Dosyaları /app/files klasörüne kaydeder
    - Benzersiz dosya adları (timestamp) verir
    """
    # Programda kayıt var mı kontrol et
    schedule_count = db.query(Schedule).count()
    if schedule_count == 0:
        raise HTTPException(
            status_code=404,
            detail="Henüz ders programı oluşturulmamış. Önce /generate-schedule çağırın.",
        )

    # Tüm sınıfları bul
    classroom_ids = (
        db.query(Schedule.classroom_id)
        .distinct()
        .all()
    )
    classroom_ids = [cid[0] for cid in classroom_ids]

    classrooms = db.query(Classroom).filter(Classroom.id.in_(classroom_ids)).all()
    if not classrooms:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    pdf_results: list[dict] = []

    for classroom in classrooms:
        try:
            entries = (
                db.query(Schedule)
                .options(
                    joinedload(Schedule.teacher),
                    joinedload(Schedule.course),
                )
                .filter(Schedule.classroom_id == classroom.id)
                .all()
            )

            pdf_entries = [
                {
                    "day": e.day,
                    "hour": e.hour,
                    "course_name": e.course.name if e.course else "",
                    "teacher_name": e.teacher.name if e.teacher else "",
                }
                for e in entries
            ]

            filepath, filename = generate_classroom_pdf(
                classroom_name=classroom.name,
                school_name=school_name,
                entries=pdf_entries,
                num_periods=settings.MAX_PERIODS_PER_DAY,
            )

            pdf_results.append({
                "classroom_id": classroom.id,
                "classroom_name": classroom.name,
                "file_url": f"/files/{filename}",
                "lesson_count": len(pdf_entries),
            })

        except Exception as e:
            pdf_results.append({
                "classroom_id": classroom.id,
                "classroom_name": classroom.name,
                "file_url": None,
                "error": str(e),
            })

    return {
        "success": True,
        "message": f"{len([p for p in pdf_results if p.get('file_url')])} sınıf için PDF oluşturuldu",
        "pdfs": pdf_results,
    }


# ─── List Schedule ────────────────────────────────────────────────────────────

@router.get("/")
def list_schedule(db: Session = Depends(get_db)):
    """Mevcut ders programını getir."""
    entries = (
        db.query(Schedule)
        .options(
            joinedload(Schedule.classroom),
            joinedload(Schedule.teacher),
            joinedload(Schedule.course),
        )
        .order_by(Schedule.day, Schedule.hour)
        .all()
    )
    return [
        {
            "id": e.id,
            "classroom_id": e.classroom_id,
            "classroom_name": e.classroom.name if e.classroom else "",
            "teacher_id": e.teacher_id,
            "teacher_name": e.teacher.name if e.teacher else "",
            "course_id": e.course_id,
            "course_name": e.course.name if e.course else "",
            "day": e.day,
            "hour": e.hour,
        }
        for e in entries
    ]


# ─── By Classroom ────────────────────────────────────────────────────────────

@router.get("/classroom/{classroom_id}")
def get_schedule_by_classroom(classroom_id: int, db: Session = Depends(get_db)):
    """Belirli bir sınıfın ders programını getir."""
    classroom = db.query(Classroom).filter(Classroom.id == classroom_id).first()
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    entries = (
        db.query(Schedule)
        .options(joinedload(Schedule.teacher), joinedload(Schedule.course))
        .filter(Schedule.classroom_id == classroom_id)
        .order_by(Schedule.day, Schedule.hour)
        .all()
    )
    return {
        "classroom": classroom.name,
        "entries": [
            {
                "day": e.day,
                "hour": e.hour,
                "course_name": e.course.name if e.course else "",
                "teacher_name": e.teacher.name if e.teacher else "",
            }
            for e in entries
        ],
    }


# ─── Delete ───────────────────────────────────────────────────────────────────

@router.delete("/", status_code=204)
def clear_schedule(db: Session = Depends(get_db)):
    """Mevcut ders programını tamamen sil."""
    db.query(Schedule).delete()
    db.commit()
    return None
