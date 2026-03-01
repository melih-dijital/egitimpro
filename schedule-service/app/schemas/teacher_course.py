from pydantic import BaseModel


class TeacherCourseCreate(BaseModel):
    teacher_id: int
    course_id: int


class TeacherCourseResponse(BaseModel):
    teacher_id: int
    course_id: int
    teacher_name: str = ""
    course_name: str = ""

    class Config:
        from_attributes = True
