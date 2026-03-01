from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Classroom(Base):
    __tablename__ = "classrooms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    grade_level = Column(Integer, nullable=False)  # Sınıf seviyesi (1-12)

    courses = relationship("Course", back_populates="classroom")
    schedules = relationship("Schedule", back_populates="classroom")

    def __repr__(self):
        return f"<Classroom(id={self.id}, name='{self.name}', grade={self.grade_level})>"
