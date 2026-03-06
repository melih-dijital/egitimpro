from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.auth import get_current_user
from app.dependencies import get_school_id
from app.models.classroom import Classroom
from app.models.schedule import Schedule

router = APIRouter()


# ─── List Schedule ────────────────────────────────────────────────────────────

@router.get("/")
def list_schedule(
    schedule_run_id: int = Query(None, description="Belirli bir run'ın programını getir"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Mevcut ders programını getir."""
    query = (
        db.query(Schedule)
        .options(
            joinedload(Schedule.classroom),
            joinedload(Schedule.teacher),
            joinedload(Schedule.course),
        )
        .filter(Schedule.school_id == school_id)
    )

    if schedule_run_id:
        query = query.filter(Schedule.schedule_run_id == schedule_run_id)

    entries = query.order_by(Schedule.day, Schedule.hour).all()

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
            "schedule_run_id": e.schedule_run_id,
        }
        for e in entries
    ]


# ─── By Classroom ────────────────────────────────────────────────────────────

@router.get("/classroom/{classroom_id}")
def get_schedule_by_classroom(
    classroom_id: int,
    schedule_run_id: int = Query(None, description="Belirli bir run'ın programını getir"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Belirli bir sınıfın ders programını getir."""
    classroom = (
        db.query(Classroom)
        .filter(Classroom.id == classroom_id, Classroom.school_id == school_id)
        .first()
    )
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    query = (
        db.query(Schedule)
        .options(joinedload(Schedule.teacher), joinedload(Schedule.course))
        .filter(Schedule.classroom_id == classroom_id, Schedule.school_id == school_id)
    )

    if schedule_run_id:
        query = query.filter(Schedule.schedule_run_id == schedule_run_id)

    entries = query.order_by(Schedule.day, Schedule.hour).all()

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
def clear_schedule(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Mevcut ders programını tamamen sil (sadece bu okulun)."""
    db.query(Schedule).filter(Schedule.school_id == school_id).delete(synchronize_session=False)
    db.commit()
    return None
