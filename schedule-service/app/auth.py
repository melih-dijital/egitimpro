"""
Supabase JWT Authentication Dependency.

Her /api/v1 endpoint'i bu dependency üzerinden korunur.
Authorization: Bearer <supabase_token> header'ı zorunludur.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

from app.config import settings

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Supabase JWT token'ı doğrular ve kullanıcı bilgilerini döner.

    Returns:
        dict: {"user_id": str, "email": str | None, ...}

    Raises:
        HTTPException 401: Token yoksa veya geçersizse
    """
    token = credentials.credentials

    try:
        unverified_header = jwt.get_unverified_header(token)
        alg = unverified_header.get("alg", "HS256")

        if alg == "RS256":
            import urllib.request
            import tempfile
            from jwt import PyJWKClient
            
            # Supabase JWKS endpoint
            jwks_url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/jwks"
            jwks_client = PyJWKClient(jwks_url)
            signing_key = jwks_client.get_signing_key_from_jwt(token)
            key = signing_key.key
        else:
            # Fallback to symmetric HS256 secret from .env
            key = settings.SUPABASE_JWT_SECRET
            alg = "HS256"

        payload = jwt.decode(
            token,
            key,
            algorithms=[alg],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token süresi dolmuş",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Geçersiz token: {str(e)} (alg: {unverified_header.get('alg', 'belirsiz')})",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token'da kullanıcı bilgisi bulunamadı",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {
        "user_id": user_id,
        "email": payload.get("email"),
        "role": payload.get("role", "authenticated"),
    }
