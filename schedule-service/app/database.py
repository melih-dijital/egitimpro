from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,       # Bağlantı kopmuşsa otomatik yenile
    pool_size=10,              # Havuzdaki sabit bağlantı sayısı
    max_overflow=20,           # Yoğunlukta ek bağlantı limiti
    pool_timeout=30,           # Havuzdan bağlantı bekleme süresi (sn)
    pool_recycle=1800,         # 30 dk sonra bağlantıyı yenile (PostgreSQL idle timeout)
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI dependency injection — her request için bir DB session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
