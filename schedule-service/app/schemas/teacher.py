from pydantic import BaseModel, Field
from typing import Optional


class UnavailableTime(BaseModel):
    day: int = Field(..., ge=0, le=4, description="0=Pazartesi, 4=Cuma")
    hour: int = Field(..., ge=1, le=8, description="Ders saati (1-8)")


class TeacherCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    max_daily_hours: int = Field(default=8, ge=1, le=8)
    unavailable_times: list[UnavailableTime] = Field(default_factory=list)


class TeacherUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    max_daily_hours: Optional[int] = Field(None, ge=1, le=8)
    unavailable_times: Optional[list[UnavailableTime]] = None


class TeacherResponse(BaseModel):
    id: int
    name: str
    max_daily_hours: int
    unavailable_times: list[UnavailableTime] = []

    class Config:
        from_attributes = True
