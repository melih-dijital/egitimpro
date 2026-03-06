from sqlalchemy import Column, Integer, String, JSON
from sqlalchemy.orm import relationship

from app.database import Base


class Teacher(Base):
    __tablename__ = "teachers"

    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, nullable=False, index=True)
    name = Column(String(200), nullable=False)
    unavailable_times = Column(JSON, default=list, nullable=False)
    # Format: [{"day": 0, "hour": 1}, {"day": 2, "hour": 3}, ...]
    # day: 0=Pazartesi, 4=Cuma | hour: 1-8
    max_daily_hours = Column(Integer, default=8, nullable=False)

    # Many-to-many relationship with Course through TeacherCourse
    teacher_courses = relationship("TeacherCourse", back_populates="teacher", cascade="all, delete-orphan")
    courses = relationship("Course", secondary="teacher_courses", viewonly=True)

    # Schedule entries where this teacher is assigned
    schedules = relationship("Schedule", back_populates="teacher")

    def __repr__(self):
        return f"<Teacher(id={self.id}, name='{self.name}', school_id={self.school_id})>"
