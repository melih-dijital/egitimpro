from pydantic import BaseModel, Field
from typing import Optional


class CourseCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    weekly_hours: int = Field(..., ge=1, le=40, description="Haftalık ders saati")
    classroom_id: int


class CourseUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    weekly_hours: Optional[int] = Field(None, ge=1, le=40)
    classroom_id: Optional[int] = None


class CourseResponse(BaseModel):
    id: int
    name: str
    weekly_hours: int
    classroom_id: int
    classroom_name: str = ""

    class Config:
        from_attributes = True
