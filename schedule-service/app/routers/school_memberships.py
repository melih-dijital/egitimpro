from fastapi import APIRouter, Depends, status
from sqlalchemy import func, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.user_school_membership import UserSchoolMembership

router = APIRouter()


@router.post("/bootstrap", status_code=status.HTTP_200_OK)
def bootstrap_school_membership(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Kullanıcının aktif okul üyeliğini hazırlar.

    - Üyelik zaten varsa mevcut üyeliği döner
    - Yoksa kullanıcı için yeni bir school_id oluşturup admin üyeliği açar
    """
    existing_membership = (
        db.query(UserSchoolMembership)
        .filter(UserSchoolMembership.user_id == current_user["user_id"])
        .order_by(UserSchoolMembership.id.asc())
        .first()
    )
    if existing_membership:
        return {
            "school_id": existing_membership.school_id,
            "role": existing_membership.role,
            "created": False,
        }

    # Ayrı bir schools tablosu olmadığı için school_id üretimini serialize ediyoruz.
    db.execute(text("LOCK TABLE user_school_memberships IN EXCLUSIVE MODE"))

    existing_membership = (
        db.query(UserSchoolMembership)
        .filter(UserSchoolMembership.user_id == current_user["user_id"])
        .order_by(UserSchoolMembership.id.asc())
        .first()
    )
    if existing_membership:
        return {
            "school_id": existing_membership.school_id,
            "role": existing_membership.role,
            "created": False,
        }

    next_school_id = (db.query(func.max(UserSchoolMembership.school_id)).scalar() or 0) + 1
    membership = UserSchoolMembership(
        user_id=current_user["user_id"],
        school_id=next_school_id,
        role="admin",
    )
    db.add(membership)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        membership = (
            db.query(UserSchoolMembership)
            .filter(UserSchoolMembership.user_id == current_user["user_id"])
            .order_by(UserSchoolMembership.id.asc())
            .first()
        )
        if membership:
            return {
                "school_id": membership.school_id,
                "role": membership.role,
                "created": False,
            }
        raise

    db.refresh(membership)
    return {
        "school_id": membership.school_id,
        "role": membership.role,
        "created": True,
    }
