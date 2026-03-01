from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    classroom_id = Column(Integer, ForeignKey("classrooms.id", ondelete="CASCADE"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    day = Column(Integer, nullable=False)   # 0=Pazartesi, 4=Cuma
    hour = Column(Integer, nullable=False)  # 1-8

    classroom = relationship("Classroom", back_populates="schedules")
    teacher = relationship("Teacher", back_populates="schedules")
    course = relationship("Course", back_populates="schedules")

    def __repr__(self):
        return f"<Schedule(id={self.id}, day={self.day}, hour={self.hour})>"
