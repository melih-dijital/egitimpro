from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.auth import get_current_user
from app.dependencies import get_school_id
from app.models.course import Course
from app.models.classroom import Classroom
from app.models.schedule import Schedule
from app.models.schedule_run import ScheduleRun
from app.models.pdf_file import PdfFile
from app.algorithms.scheduler import generate_schedule
from app.services.pdf_generator import generate_classroom_pdf
from app.schemas.schedule_run import ScheduleRunResponse, ScheduleRunBrief
from app.schemas.pdf_file import PdfFileResponse
from app.config import settings

router = APIRouter()


# ─── Create Schedule Run (Generate Schedule) ─────────────────────────────────

@router.post("/", status_code=201)
def create_schedule_run(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """
    OR-Tools CP-SAT ile otomatik ders programı oluştur.

    1. Yeni ScheduleRun kaydı oluşturur
    2. Veritabanından öğretmen, ders, sınıf ve eşleştirmeleri çeker (school_id filtreli)
    3. CP-SAT algoritmasını çalıştırır
    4. Sonucu Schedule tablosuna kaydeder
    5. Başarı durumunu JSON olarak döndürür
    """
    # Yeni schedule run oluştur
    run = ScheduleRun(
        school_id=school_id,
        created_by_user_id=current_user["user_id"],
        status="running",
        meta={"initiated_at": datetime.now(timezone.utc).isoformat()},
    )
    db.add(run)
    db.commit()
    db.refresh(run)

    try:
        result = generate_schedule(db, school_id)
    except Exception as e:
        run.status = "failed"
        run.meta = {**(run.meta or {}), "error": str(e)}
        db.commit()
        raise HTTPException(
            status_code=500,
            detail=f"Algoritma çalıştırılırken hata oluştu: {str(e)}",
        )

    if not result.success:
        run.status = "failed"
        run.meta = {**(run.meta or {}), "error": result.message}
        db.commit()
        raise HTTPException(status_code=422, detail=result.message)

    # Eski programı temizle (sadece bu okulun, bu run hariç)
    db.query(Schedule).filter(
        Schedule.school_id == school_id,
        Schedule.schedule_run_id != run.id,
    ).delete(synchronize_session=False)

    for entry in result.entries:
        row = Schedule(
            school_id=school_id,
            schedule_run_id=run.id,
            classroom_id=entry["classroom_id"],
            teacher_id=entry["teacher_id"],
            course_id=entry["course_id"],
            day=entry["day"],
            hour=entry["hour"],
        )
        db.add(row)

    run.status = "completed"
    run.meta = {
        **(run.meta or {}),
        "completed_at": datetime.now(timezone.utc).isoformat(),
        "total_entries": len(result.entries),
    }
    db.commit()

    # Sınıf bazlı özet
    classroom_summary: dict[int, int] = {}
    for entry in result.entries:
        cl_id = entry["classroom_id"]
        classroom_summary[cl_id] = classroom_summary.get(cl_id, 0) + 1

    classrooms = (
        db.query(Classroom)
        .filter(Classroom.id.in_(classroom_summary.keys()), Classroom.school_id == school_id)
        .all()
    )
    cl_names = {c.id: c.name for c in classrooms}

    return {
        "success": True,
        "message": result.message,
        "schedule_run_id": run.id,
        "status": run.status,
        "created_at": run.created_at.isoformat(),
        "total_entries": len(result.entries),
        "classrooms": [
            {"classroom_id": cl_id, "classroom_name": cl_names.get(cl_id, ""), "lesson_count": count}
            for cl_id, count in classroom_summary.items()
        ],
    }


# ─── List Schedule Runs ──────────────────────────────────────────────────────

@router.get("/", response_model=list[ScheduleRunBrief])
def list_schedule_runs(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Okulun tüm program üretim geçmişini listele."""
    return (
        db.query(ScheduleRun)
        .filter(ScheduleRun.school_id == school_id)
        .order_by(ScheduleRun.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


# ─── Get Schedule Run Detail ─────────────────────────────────────────────────

@router.get("/{run_id}", response_model=ScheduleRunResponse)
def get_schedule_run(
    run_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Schedule run detayını getir."""
    run = (
        db.query(ScheduleRun)
        .filter(ScheduleRun.id == run_id, ScheduleRun.school_id == school_id)
        .first()
    )
    if not run:
        raise HTTPException(status_code=404, detail="Schedule run bulunamadı")
    return run


# ─── Generate PDF for a Run ──────────────────────────────────────────────────

@router.post("/{run_id}/pdf", status_code=201)
def generate_pdf_for_run(
    run_id: int,
    school_name: str = Query(default="Okul Adı", description="PDF başlığında görünecek okul adı"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """
    Belirtilen schedule run için sınıf bazlı PDF'ler oluştur.

    - Her sınıf için ayrı tablo formatında PDF üretir
    - Dosyaları /files/{school_id}/{run_id}/ klasörüne kaydeder
    - pdf_files tablosuna kayıt eder
    """
    # Run'ın bu okula ait olduğunu doğrula
    run = (
        db.query(ScheduleRun)
        .filter(ScheduleRun.id == run_id, ScheduleRun.school_id == school_id)
        .first()
    )
    if not run:
        raise HTTPException(status_code=404, detail="Schedule run bulunamadı")

    if run.status != "completed":
        raise HTTPException(status_code=400, detail="Bu run henüz tamamlanmamış veya başarısız olmuş")

    # Bu run'daki programda kayıt var mı kontrol et
    schedule_count = (
        db.query(Schedule)
        .filter(Schedule.schedule_run_id == run_id, Schedule.school_id == school_id)
        .count()
    )
    if schedule_count == 0:
        raise HTTPException(
            status_code=404,
            detail="Bu run için ders programı kaydı bulunamadı.",
        )

    # Tüm sınıfları bul
    classroom_ids = (
        db.query(Schedule.classroom_id)
        .filter(Schedule.schedule_run_id == run_id, Schedule.school_id == school_id)
        .distinct()
        .all()
    )
    classroom_ids = [cid[0] for cid in classroom_ids]

    classrooms = (
        db.query(Classroom)
        .filter(Classroom.id.in_(classroom_ids), Classroom.school_id == school_id)
        .all()
    )
    if not classrooms:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    # Eski PDF kayıtlarını temizle (bu run için)
    db.query(PdfFile).filter(
        PdfFile.schedule_run_id == run_id,
        PdfFile.school_id == school_id,
    ).delete(synchronize_session=False)

    pdf_results: list[dict] = []

    for classroom in classrooms:
        try:
            entries = (
                db.query(Schedule)
                .options(
                    joinedload(Schedule.teacher),
                    joinedload(Schedule.course),
                )
                .filter(
                    Schedule.classroom_id == classroom.id,
                    Schedule.schedule_run_id == run_id,
                    Schedule.school_id == school_id,
                )
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

            filepath, relative_path = generate_classroom_pdf(
                school_id=school_id,
                schedule_run_id=run_id,
                classroom_name=classroom.name,
                school_name=school_name,
                entries=pdf_entries,
                num_periods=settings.MAX_PERIODS_PER_DAY,
            )

            # pdf_files tablosuna kaydet
            pdf_record = PdfFile(
                school_id=school_id,
                schedule_run_id=run_id,
                classroom_id=classroom.id,
                file_path=relative_path,
            )
            db.add(pdf_record)

            pdf_results.append({
                "classroom_id": classroom.id,
                "classroom_name": classroom.name,
                "file_url": f"/files/{relative_path}",
                "lesson_count": len(pdf_entries),
            })

        except Exception as e:
            pdf_results.append({
                "classroom_id": classroom.id,
                "classroom_name": classroom.name,
                "file_url": None,
                "error": str(e),
            })

    db.commit()

    return {
        "success": True,
        "schedule_run_id": run_id,
        "message": f"{len([p for p in pdf_results if p.get('file_url')])} sınıf için PDF oluşturuldu",
        "pdfs": pdf_results,
    }


# ─── List PDFs for a Run ─────────────────────────────────────────────────────

@router.get("/{run_id}/pdfs", response_model=list[PdfFileResponse])
def list_run_pdfs(
    run_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Bir schedule run'a ait PDF dosyalarını listele."""
    run = (
        db.query(ScheduleRun)
        .filter(ScheduleRun.id == run_id, ScheduleRun.school_id == school_id)
        .first()
    )
    if not run:
        raise HTTPException(status_code=404, detail="Schedule run bulunamadı")

    return (
        db.query(PdfFile)
        .filter(PdfFile.schedule_run_id == run_id, PdfFile.school_id == school_id)
        .all()
    )


# ─── Delete Schedule Run ─────────────────────────────────────────────────────

@router.delete("/{run_id}", status_code=204)
def delete_schedule_run(
    run_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Schedule run ve ilişkili tüm verileri sil."""
    run = (
        db.query(ScheduleRun)
        .filter(ScheduleRun.id == run_id, ScheduleRun.school_id == school_id)
        .first()
    )
    if not run:
        raise HTTPException(status_code=404, detail="Schedule run bulunamadı")

    db.delete(run)
    db.commit()
    return None
