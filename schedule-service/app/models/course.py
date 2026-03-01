from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    weekly_hours = Column(Integer, nullable=False)  # Haftalık ders saati
    classroom_id = Column(Integer, ForeignKey("classrooms.id", ondelete="CASCADE"), nullable=False)

    classroom = relationship("Classroom", back_populates="courses")

    # Many-to-many relationship with Teacher through TeacherCourse
    teacher_courses = relationship("TeacherCourse", back_populates="course", cascade="all, delete-orphan")
    teachers = relationship("Teacher", secondary="teacher_courses", viewonly=True)

    # Schedule entries for this course
    schedules = relationship("Schedule", back_populates="course")

    def __repr__(self):
        return f"<Course(id={self.id}, name='{self.name}', weekly_hours={self.weekly_hours})>"
