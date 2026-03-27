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

        if alg in ["RS256", "ES256"]:
            from jwt import PyJWKClient
            from jwt.exceptions import PyJWKClientError
            
            if not settings.SUPABASE_URL or "your-project" in settings.SUPABASE_URL:
                raise Exception("Sunucunun .env dosyasındaki SUPABASE_URL ayarı eksik veya geçersiz.")
            
            if not getattr(settings, "SUPABASE_ANON_KEY", None) or "your-supabase-anon-key-here" in settings.SUPABASE_ANON_KEY:
                raise Exception("Sunucunun .env dosyasında SUPABASE_ANON_KEY eksik. ES256/RS256 doğrulaması için bu anahtar gereklidir.")

            # Supabase JWKS endpoint
            jwks_url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/jwks"
            try:
                # Supabase REST API requires the apikey (anon key) in headers
                jwks_client = PyJWKClient(jwks_url, headers={"apikey": settings.SUPABASE_ANON_KEY})
                signing_key = jwks_client.get_signing_key_from_jwt(token)
                key = signing_key.key
            except PyJWKClientError as e:
                raise Exception(
                    f"JWKS indirilemedi. Lütfen .env dosyanızdaki SUPABASE_URL "
                    f"değerinin tam olarak 'https://<id>.supabase.co' olduğundan emin olun "
                    f"(Şu an denenen adres: {jwks_url}). Hata Detayı: {str(e)}"
                )
        else:
            # Fallback to symmetric HS256 secret from .env
            key = settings.SUPABASE_JWT_SECRET
            alg = "HS256"
    except Exception as e:
        # Catch errors during header parsing or key retrieval (e.g., malformed token)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token başlığı veya anahtarı alınamadı: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
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
