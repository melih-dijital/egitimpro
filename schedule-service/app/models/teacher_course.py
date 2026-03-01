from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class TeacherCourse(Base):
    __tablename__ = "teacher_courses"

    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), primary_key=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), primary_key=True)

    teacher = relationship("Teacher", back_populates="teacher_courses")
    course = relationship("Course", back_populates="teacher_courses")

    def __repr__(self):
        return f"<TeacherCourse(teacher_id={self.teacher_id}, course_id={self.course_id})>"
