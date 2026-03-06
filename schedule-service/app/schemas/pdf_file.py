from pydantic import BaseModel
from datetime import datetime


class PdfFileResponse(BaseModel):
    id: int
    school_id: int
    schedule_run_id: int
    classroom_id: int
    file_path: str
    created_at: datetime

    class Config:
        from_attributes = True
