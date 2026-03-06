from sqlalchemy import Column, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class Classroom(Base):
    __tablename__ = "classrooms"

    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    grade_level = Column(Integer, nullable=False)  # Sınıf seviyesi (1-12)

    courses = relationship("Course", back_populates="classroom")
    schedules = relationship("Schedule", back_populates="classroom")

    __table_args__ = (
        UniqueConstraint("school_id", "name", name="uq_classroom_school_name"),
    )

    def __repr__(self):
        return f"<Classroom(id={self.id}, name='{self.name}', school_id={self.school_id})>"
