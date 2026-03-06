from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from app.database import Base


class PdfFile(Base):
    __tablename__ = "pdf_files"

    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, nullable=False, index=True)
    schedule_run_id = Column(Integer, ForeignKey("schedule_runs.id", ondelete="CASCADE"), nullable=False)
    classroom_id = Column(Integer, ForeignKey("classrooms.id", ondelete="CASCADE"), nullable=False)
    file_path = Column(String(500), nullable=False)  # Relative path: {school_id}/{run_id}/{name}.pdf
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    # Relationships
    schedule_run = relationship("ScheduleRun", back_populates="pdf_files")
    classroom = relationship("Classroom")

    def __repr__(self):
        return f"<PdfFile(id={self.id}, file_path='{self.file_path}')>"
