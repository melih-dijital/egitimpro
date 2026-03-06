from sqlalchemy import Column, Integer, String, UniqueConstraint
from app.database import Base


class UserSchoolMembership(Base):
    __tablename__ = "user_school_memberships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(255), nullable=False, index=True)  # Supabase UUID
    school_id = Column(Integer, nullable=False, index=True)
    role = Column(String(50), nullable=False, default="admin")  # admin | teacher | viewer

    __table_args__ = (
        UniqueConstraint("user_id", "school_id", name="uq_user_school"),
    )

    def __repr__(self):
        return f"<UserSchoolMembership(user_id='{self.user_id}', school_id={self.school_id}, role='{self.role}')>"
