"""
Tenant İzolasyonu Dependencies.

X-School-Id header üzerinden school_id çıkarır ve yetki kontrolü yapar.
"""

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.user_school_membership import UserSchoolMembership


def get_school_id(
    x_school_id: int = Header(..., alias="X-School-Id"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> int:
    """
    X-School-Id header'ından school_id çıkarır ve kullanıcının bu okula
    erişim yetkisi olup olmadığını kontrol eder.

    Returns:
        int: Doğrulanmış school_id

    Raises:
        HTTPException 400: X-School-Id header yoksa
        HTTPException 403: Kullanıcının bu okula erişim yetkisi yoksa
    """
    membership = (
        db.query(UserSchoolMembership)
        .filter(
            UserSchoolMembership.user_id == current_user["user_id"],
            UserSchoolMembership.school_id == x_school_id,
        )
        .first()
    )

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu okula erişim yetkiniz yok",
        )

    return x_school_id
