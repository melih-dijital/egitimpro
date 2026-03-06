from sqlalchemy import Column, Integer, String, DateTime, JSON
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from app.database import Base


class ScheduleRun(Base):
    __tablename__ = "schedule_runs"

    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, nullable=False, index=True)
    created_by_user_id = Column(String(255), nullable=False)  # Supabase UUID
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    status = Column(String(50), nullable=False, default="running")  # running | completed | failed
    meta = Column(JSON, default=dict)

    # Relationships
    schedules = relationship("Schedule", back_populates="schedule_run")
    pdf_files = relationship("PdfFile", back_populates="schedule_run")

    def __repr__(self):
        return f"<ScheduleRun(id={self.id}, school_id={self.school_id}, status='{self.status}')>"
