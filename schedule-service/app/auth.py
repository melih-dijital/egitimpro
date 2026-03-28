"""
Supabase JWT Authentication Dependency.

Her /api/v1 endpoint'i bu dependency üzerinden korunur.
Authorization: Bearer <supabase_token> header'i zorunludur.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt

from app.config import settings

security = HTTPBearer()


def _normalize_public_key(value: str | None) -> str:
    """Normalize PEM values copied from .env files or dashboards."""
    if not value:
        return ""

    return value.strip().strip('"').strip("'").replace("\\n", "\n")


def _looks_like_pem_public_key(value: str | None) -> bool:
    normalized = _normalize_public_key(value)
    return (
        "BEGIN PUBLIC KEY" in normalized
        and "END PUBLIC KEY" in normalized
        and "sb_publishable_" not in normalized
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Supabase JWT token'ini dogrular ve kullanici bilgilerini doner.

    Returns:
        dict: {"user_id": str, "email": str | None, ...}

    Raises:
        HTTPException 401: Token yoksa veya gecersizse
    """
    token = credentials.credentials

    try:
        unverified_header = jwt.get_unverified_header(token)
        alg = unverified_header.get("alg", "HS256")

        if alg in ["RS256", "ES256"]:
            pub_key_env = getattr(settings, "SUPABASE_PUBLIC_KEY", None)
            normalized_pub_key = _normalize_public_key(pub_key_env)

            if normalized_pub_key and not _looks_like_pem_public_key(pub_key_env):
                raise Exception(
                    "SUPABASE_PUBLIC_KEY gecersiz gorunuyor. "
                    "Buraya sb_publishable_/anon key degil, "
                    "Supabase Dashboard -> API -> JWT Settings altindaki "
                    "PEM formatli Public Key yapistirilmalidir."
                )

            if normalized_pub_key and "your-public-key" not in normalized_pub_key:
                key = normalized_pub_key
            else:
                from jwt import PyJWKClient
                from jwt.exceptions import PyJWKClientError

                if not settings.SUPABASE_URL or "your-project" in settings.SUPABASE_URL:
                    raise Exception(
                        "Sunucunun .env dosyasindaki SUPABASE_URL ayari eksik veya gecersiz."
                    )

                jwks_url = (
                    f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"
                )
                jwks_headers = {}
                anon_key = getattr(settings, "SUPABASE_ANON_KEY", None)
                if anon_key and "your-supabase-anon-key-here" not in anon_key:
                    jwks_headers["apikey"] = anon_key

                try:
                    jwks_client = PyJWKClient(jwks_url, headers=jwks_headers)
                    signing_key = jwks_client.get_signing_key_from_jwt(token)
                    key = signing_key.key
                except PyJWKClientError as e:
                    raise Exception(
                        f"JWKS acik anahtari {jwks_url} adresinden indirilemedi. "
                        f"Supabase'in guncel endpoint'i /auth/v1/.well-known/jwks.json yoludur. "
                        f"Eger sorun devam ederse Supabase Dashboard -> API -> JWT Settings "
                        f"kismindan Public Key kopyalanip SUPABASE_PUBLIC_KEY olarak eklenmelidir. "
                        f"Hata: {str(e)}"
                    )
        else:
            key = settings.SUPABASE_JWT_SECRET
            alg = "HS256"
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token basligi veya anahtari alinamadi: {str(e)}",
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
            detail="Token suresi dolmus",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Gecersiz token: {str(e)} (alg: {unverified_header.get('alg', 'belirsiz')})",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token'da kullanici bilgisi bulunamadi",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {
        "user_id": user_id,
        "email": payload.get("email"),
        "role": payload.get("role", "authenticated"),
    }
