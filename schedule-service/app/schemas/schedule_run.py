from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class ScheduleRunResponse(BaseModel):
    id: int
    school_id: int
    created_by_user_id: str
    created_at: datetime
    status: str
    meta: Optional[dict] = None

    class Config:
        from_attributes = True


class ScheduleRunBrief(BaseModel):
    id: int
    created_at: datetime
    status: str

    class Config:
        from_attributes = True
