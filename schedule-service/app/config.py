from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # ─── Database ──────────────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql://postgres:postgres@db:5432/schedule_db"

    # ─── App ───────────────────────────────────────────────────────────────
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    APP_ENV: str = "production"  # development | staging | production
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"

    # ─── Schedule ──────────────────────────────────────────────────────────
    PDF_OUTPUT_DIR: str = "output/pdfs"
    MAX_PERIODS_PER_DAY: int = 8
    DAYS_PER_WEEK: int = 5

    # ─── Auth ──────────────────────────────────────────────────────────────
    SUPABASE_JWT_SECRET: str = ""
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""

    # ─── CORS ──────────────────────────────────────────────────────────────
    CORS_ORIGINS: str = "*"  # Comma-separated: "https://app.example.com,https://admin.example.com"

    # ─── Rate Limiting ─────────────────────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 60

    @property
    def cors_origin_list(self) -> list[str]:
        """Parse comma-separated CORS origins into a list."""
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
