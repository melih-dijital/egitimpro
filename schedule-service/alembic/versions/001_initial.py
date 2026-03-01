"""initial tables

Revision ID: 001_initial
Revises:
Create Date: 2026-03-01

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Teachers
    op.create_table(
        "teachers",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("unavailable_times", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("max_daily_hours", sa.Integer(), nullable=False, server_default="8"),
    )
    op.create_index("ix_teachers_id", "teachers", ["id"])

    # Classrooms
    op.create_table(
        "classrooms",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(100), nullable=False, unique=True),
        sa.Column("grade_level", sa.Integer(), nullable=False),
    )
    op.create_index("ix_classrooms_id", "classrooms", ["id"])

    # Courses
    op.create_table(
        "courses",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("weekly_hours", sa.Integer(), nullable=False),
        sa.Column(
            "classroom_id",
            sa.Integer(),
            sa.ForeignKey("classrooms.id", ondelete="CASCADE"),
            nullable=False,
        ),
    )
    op.create_index("ix_courses_id", "courses", ["id"])

    # TeacherCourse (many-to-many)
    op.create_table(
        "teacher_courses",
        sa.Column(
            "teacher_id",
            sa.Integer(),
            sa.ForeignKey("teachers.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "course_id",
            sa.Integer(),
            sa.ForeignKey("courses.id", ondelete="CASCADE"),
            primary_key=True,
        ),
    )

    # Schedules
    op.create_table(
        "schedules",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "classroom_id",
            sa.Integer(),
            sa.ForeignKey("classrooms.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "teacher_id",
            sa.Integer(),
            sa.ForeignKey("teachers.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "course_id",
            sa.Integer(),
            sa.ForeignKey("courses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("day", sa.Integer(), nullable=False),
        sa.Column("hour", sa.Integer(), nullable=False),
    )
    op.create_index("ix_schedules_id", "schedules", ["id"])


def downgrade() -> None:
    op.drop_table("schedules")
    op.drop_table("teacher_courses")
    op.drop_table("courses")
    op.drop_table("classrooms")
    op.drop_table("teachers")
