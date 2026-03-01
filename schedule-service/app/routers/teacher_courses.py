from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.teacher import Teacher
from app.models.course import Course
from app.models.teacher_course import TeacherCourse
from app.schemas.teacher_course import TeacherCourseCreate, TeacherCourseResponse

router = APIRouter()


@router.post("/", response_model=TeacherCourseResponse, status_code=201)
def assign_teacher_to_course(data: TeacherCourseCreate, db: Session = Depends(get_db)):
    """Öğretmeni derse ata."""
    teacher = db.query(Teacher).filter(Teacher.id == data.teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Öğretmen bulunamadı")

    course = db.query(Course).filter(Course.id == data.course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")

    # Duplicate kontrolü
    existing = (
        db.query(TeacherCourse)
        .filter(
            TeacherCourse.teacher_id == data.teacher_id,
            TeacherCourse.course_id == data.course_id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Bu eşleştirme zaten mevcut")

    assignment = TeacherCourse(teacher_id=data.teacher_id, course_id=data.course_id)
    db.add(assignment)
    db.commit()

    return {
        "teacher_id": teacher.id,
        "course_id": course.id,
        "teacher_name": teacher.name,
        "course_name": course.name,
    }


@router.get("/", response_model=list[TeacherCourseResponse])
def list_assignments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Tüm öğretmen-ders eşleştirmelerini listele."""
    assignments = db.query(TeacherCourse).offset(skip).limit(limit).all()
    result = []
    for a in assignments:
        teacher = db.query(Teacher).filter(Teacher.id == a.teacher_id).first()
        course = db.query(Course).filter(Course.id == a.course_id).first()
        result.append({
            "teacher_id": a.teacher_id,
            "course_id": a.course_id,
            "teacher_name": teacher.name if teacher else "",
            "course_name": course.name if course else "",
        })
    return result


@router.delete("/{teacher_id}/{course_id}", status_code=204)
def remove_assignment(teacher_id: int, course_id: int, db: Session = Depends(get_db)):
    """Öğretmen-ders eşleştirmesini kaldır."""
    assignment = (
        db.query(TeacherCourse)
        .filter(
            TeacherCourse.teacher_id == teacher_id,
            TeacherCourse.course_id == course_id,
        )
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=404, detail="Eşleştirme bulunamadı")

    db.delete(assignment)
    db.commit()
    return None
