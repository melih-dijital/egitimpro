from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.course import Course
from app.models.classroom import Classroom
from app.schemas.course import CourseCreate, CourseUpdate, CourseResponse

router = APIRouter()


def _enrich(course: Course) -> dict:
    return {
        "id": course.id,
        "name": course.name,
        "weekly_hours": course.weekly_hours,
        "classroom_id": course.classroom_id,
        "classroom_name": course.classroom.name if course.classroom else "",
    }


@router.post("/", response_model=CourseResponse, status_code=201)
def create_course(data: CourseCreate, db: Session = Depends(get_db)):
    """Yeni ders ekle."""
    classroom = db.query(Classroom).filter(Classroom.id == data.classroom_id).first()
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    course = Course(**data.model_dump())
    db.add(course)
    db.commit()
    db.refresh(course)

    course = (
        db.query(Course)
        .options(joinedload(Course.classroom))
        .filter(Course.id == course.id)
        .first()
    )
    return _enrich(course)


@router.get("/", response_model=list[CourseResponse])
def list_courses(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Tüm dersleri listele."""
    courses = (
        db.query(Course)
        .options(joinedload(Course.classroom))
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [_enrich(c) for c in courses]


@router.get("/{course_id}", response_model=CourseResponse)
def get_course(course_id: int, db: Session = Depends(get_db)):
    """Ders detayını getir."""
    course = (
        db.query(Course)
        .options(joinedload(Course.classroom))
        .filter(Course.id == course_id)
        .first()
    )
    if not course:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")
    return _enrich(course)


@router.put("/{course_id}", response_model=CourseResponse)
def update_course(course_id: int, data: CourseUpdate, db: Session = Depends(get_db)):
    """Ders bilgilerini güncelle."""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")

    update_data = data.model_dump(exclude_unset=True)

    if "classroom_id" in update_data:
        if not db.query(Classroom).filter(Classroom.id == update_data["classroom_id"]).first():
            raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    for key, value in update_data.items():
        setattr(course, key, value)

    db.commit()
    db.refresh(course)

    course = (
        db.query(Course)
        .options(joinedload(Course.classroom))
        .filter(Course.id == course.id)
        .first()
    )
    return _enrich(course)


@router.delete("/{course_id}", status_code=204)
def delete_course(course_id: int, db: Session = Depends(get_db)):
    """Dersi sil."""
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")
    db.delete(course)
    db.commit()
    return None
