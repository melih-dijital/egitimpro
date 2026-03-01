from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ScheduleCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, description="Program adı")


class ScheduleEntryResponse(BaseModel):
    id: int
    course_id: int
    course_name: str = ""
    teacher_name: str = ""
    classroom_name: str = ""
    day_of_week: int
    period: int

    class Config:
        from_attributes = True


class ScheduleResponse(BaseModel):
    id: int
    name: str
    created_at: datetime
    entries: list[ScheduleEntryResponse] = []

    class Config:
        from_attributes = True


class ScheduleBriefResponse(BaseModel):
    id: int
    name: str
    created_at: datetime

    class Config:
        from_attributes = True


class ScheduleGenerateResponse(BaseModel):
    schedule: ScheduleBriefResponse
    message: str
    total_entries: int
