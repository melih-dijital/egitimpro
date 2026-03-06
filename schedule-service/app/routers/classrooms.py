from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.auth import get_current_user
from app.dependencies import get_school_id
from app.models.classroom import Classroom
from app.schemas.classroom import ClassroomCreate, ClassroomUpdate, ClassroomResponse

router = APIRouter()


@router.post("/", response_model=ClassroomResponse, status_code=201)
def create_classroom(
    data: ClassroomCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Yeni sınıf ekle."""
    existing = (
        db.query(Classroom)
        .filter(Classroom.name == data.name, Classroom.school_id == school_id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Bu sınıf adı zaten mevcut")

    classroom = Classroom(school_id=school_id, **data.model_dump())
    db.add(classroom)
    db.commit()
    db.refresh(classroom)
    return classroom


@router.get("/", response_model=list[ClassroomResponse])
def list_classrooms(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Tüm sınıfları listele."""
    return (
        db.query(Classroom)
        .filter(Classroom.school_id == school_id)
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/{classroom_id}", response_model=ClassroomResponse)
def get_classroom(
    classroom_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Sınıf detayını getir."""
    classroom = (
        db.query(Classroom)
        .filter(Classroom.id == classroom_id, Classroom.school_id == school_id)
        .first()
    )
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")
    return classroom


@router.put("/{classroom_id}", response_model=ClassroomResponse)
def update_classroom(
    classroom_id: int,
    data: ClassroomUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Sınıf bilgilerini güncelle."""
    classroom = (
        db.query(Classroom)
        .filter(Classroom.id == classroom_id, Classroom.school_id == school_id)
        .first()
    )
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(classroom, key, value)

    db.commit()
    db.refresh(classroom)
    return classroom


@router.delete("/{classroom_id}", status_code=204)
def delete_classroom(
    classroom_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
    school_id: int = Depends(get_school_id),
):
    """Sınıfı sil."""
    classroom = (
        db.query(Classroom)
        .filter(Classroom.id == classroom_id, Classroom.school_id == school_id)
        .first()
    )
    if not classroom:
        raise HTTPException(status_code=404, detail="Sınıf bulunamadı")
    db.delete(classroom)
    db.commit()
    return None
