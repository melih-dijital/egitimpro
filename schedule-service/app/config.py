from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://postgres:postgres@db:5432/schedule_db"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    PDF_OUTPUT_DIR: str = "output/pdfs"
    MAX_PERIODS_PER_DAY: int = 8
    DAYS_PER_WEEK: int = 5

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
