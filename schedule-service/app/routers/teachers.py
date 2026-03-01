import io

import pandas as pd
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.teacher import Teacher
from app.schemas.teacher import TeacherCreate, TeacherUpdate, TeacherResponse

router = APIRouter()

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


# ─── CRUD ─────────────────────────────────────────────────────────────────────

@router.post("/", response_model=TeacherResponse, status_code=201)
def create_teacher(data: TeacherCreate, db: Session = Depends(get_db)):
    """Yeni öğretmen ekle."""
    unavailable = [ut.model_dump() for ut in data.unavailable_times]

    teacher = Teacher(
        name=data.name,
        max_daily_hours=data.max_daily_hours,
        unavailable_times=unavailable,
    )
    db.add(teacher)
    db.commit()
    db.refresh(teacher)
    return teacher


@router.get("/", response_model=list[TeacherResponse])
def list_teachers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Tüm öğretmenleri listele."""
    return db.query(Teacher).offset(skip).limit(limit).all()


@router.get("/{teacher_id}", response_model=TeacherResponse)
def get_teacher(teacher_id: int, db: Session = Depends(get_db)):
    """Öğretmen detayını getir."""
    teacher = db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Öğretmen bulunamadı")
    return teacher


@router.put("/{teacher_id}", response_model=TeacherResponse)
def update_teacher(teacher_id: int, data: TeacherUpdate, db: Session = Depends(get_db)):
    """Öğretmen bilgilerini güncelle."""
    teacher = db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Öğretmen bulunamadı")

    update_data = data.model_dump(exclude_unset=True)

    if "unavailable_times" in update_data and update_data["unavailable_times"] is not None:
        update_data["unavailable_times"] = [
            ut if isinstance(ut, dict) else ut.model_dump()
            for ut in update_data["unavailable_times"]
        ]

    for key, value in update_data.items():
        setattr(teacher, key, value)

    db.commit()
    db.refresh(teacher)
    return teacher


@router.delete("/{teacher_id}", status_code=204)
def delete_teacher(teacher_id: int, db: Session = Depends(get_db)):
    """Öğretmeni sil."""
    teacher = db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(status_code=404, detail="Öğretmen bulunamadı")
    db.delete(teacher)
    db.commit()
    return None


# ─── Bulk Upload ──────────────────────────────────────────────────────────────

@router.post("/upload")
async def upload_teachers(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Excel (.xlsx) veya CSV dosyasından toplu öğretmen yükleme.

    Beklenen sütunlar:
      - name (zorunlu)
      - max_daily_hours (opsiyonel, varsayılan: 8)

    Maksimum dosya boyutu: 10 MB
    """

    # ── Dosya boyutu kontrolü ──────────────────────────────────────────────
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"Dosya boyutu 10 MB sınırını aşıyor ({len(content) / (1024*1024):.1f} MB)",
        )

    filename = (file.filename or "").lower()

    # ── Pandas ile oku ─────────────────────────────────────────────────────
    try:
        if filename.endswith(".csv"):
            df = pd.read_csv(io.BytesIO(content), encoding="utf-8-sig")
        elif filename.endswith(".xlsx"):
            df = pd.read_excel(io.BytesIO(content), engine="openpyxl")
        else:
            raise HTTPException(
                status_code=400,
                detail="Desteklenen formatlar: .csv, .xlsx",
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Dosya okunamadı: {str(e)}")

    if df.empty:
        raise HTTPException(status_code=400, detail="Dosya boş, hiç satır bulunamadı")

    # Sütun isimlerini normalize et
    df.columns = [col.strip().lower() for col in df.columns]

    if "name" not in df.columns:
        raise HTTPException(
            status_code=400,
            detail=f"'name' sütunu bulunamadı. Mevcut sütunlar: {list(df.columns)}",
        )

    # ── Satır satır işle ───────────────────────────────────────────────────
    saved: list[dict] = []
    errors: list[dict] = []

    for idx, row in df.iterrows():
        row_num = idx + 2  # Excel/CSV satır numarası (1-indexed + header)

        try:
            name = str(row.get("name", "")).strip()
            if not name or name == "nan":
                errors.append({"row": row_num, "error": "'name' alanı boş"})
                continue

            # max_daily_hours
            raw_hours = row.get("max_daily_hours", 8)
            try:
                max_hours = int(float(raw_hours)) if pd.notna(raw_hours) else 8
            except (ValueError, TypeError):
                max_hours = 8

            if max_hours < 1 or max_hours > 8:
                errors.append({
                    "row": row_num,
                    "error": f"max_daily_hours 1-8 arasında olmalı (gelen: {max_hours})",
                    "name": name,
                })
                continue

            teacher = Teacher(name=name, max_daily_hours=max_hours, unavailable_times=[])
            db.add(teacher)
            db.flush()

            saved.append({"id": teacher.id, "name": name, "max_daily_hours": max_hours})

        except Exception as e:
            errors.append({"row": row_num, "error": str(e)})

    # ── Sonuçları kaydet ───────────────────────────────────────────────────
    if saved:
        db.commit()
    else:
        db.rollback()

    return {
        "message": f"{len(saved)} öğretmen başarıyla yüklendi",
        "saved_count": len(saved),
        "error_count": len(errors),
        "saved": saved,
        "errors": errors,
    }
