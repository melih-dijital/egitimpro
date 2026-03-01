from pydantic import BaseModel, Field
from typing import Optional


class ClassroomBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    grade_level: int = Field(..., ge=1, le=12, description="Sınıf seviyesi (1-12)")


class ClassroomCreate(ClassroomBase):
    pass


class ClassroomUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    grade_level: Optional[int] = Field(None, ge=1, le=12)


class ClassroomResponse(ClassroomBase):
    id: int

    class Config:
        from_attributes = True
