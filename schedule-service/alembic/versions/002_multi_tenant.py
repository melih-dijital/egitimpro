"""multi-tenant auth and schedule runs

Revision ID: 002_multi_tenant
Revises: 001_initial
Create Date: 2026-03-05

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "002_multi_tenant"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. user_school_memberships ─────────────────────────────────────────
    op.create_table(
        "user_school_memberships",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.String(255), nullable=False),
        sa.Column("school_id", sa.Integer(), nullable=False),
        sa.Column("role", sa.String(50), nullable=False, server_default="admin"),
        sa.UniqueConstraint("user_id", "school_id", name="uq_user_school"),
    )
    op.create_index("ix_user_school_memberships_id", "user_school_memberships", ["id"])
    op.create_index("ix_user_school_memberships_user_id", "user_school_memberships", ["user_id"])
    op.create_index("ix_user_school_memberships_school_id", "user_school_memberships", ["school_id"])

    # ── 2. schedule_runs ──────────────────────────────────────────────────
    op.create_table(
        "schedule_runs",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("school_id", sa.Integer(), nullable=False),
        sa.Column("created_by_user_id", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("status", sa.String(50), nullable=False, server_default="running"),
        sa.Column("meta", sa.JSON(), nullable=True),
    )
    op.create_index("ix_schedule_runs_id", "schedule_runs", ["id"])
    op.create_index("ix_schedule_runs_school_id", "schedule_runs", ["school_id"])

    # ── 3. pdf_files ──────────────────────────────────────────────────────
    op.create_table(
        "pdf_files",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("school_id", sa.Integer(), nullable=False),
        sa.Column(
            "schedule_run_id", sa.Integer(),
            sa.ForeignKey("schedule_runs.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "classroom_id", sa.Integer(),
            sa.ForeignKey("classrooms.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_pdf_files_id", "pdf_files", ["id"])
    op.create_index("ix_pdf_files_school_id", "pdf_files", ["school_id"])

    # ── 4. Mevcut tablolara school_id ekle ─────────────────────────────────
    for table in ("teachers", "classrooms", "courses", "teacher_courses", "schedules"):
        op.add_column(table, sa.Column("school_id", sa.Integer(), nullable=True))
        op.execute(f"UPDATE {table} SET school_id = 1 WHERE school_id IS NULL")
        op.alter_column(table, "school_id", nullable=False)
        op.create_index(f"ix_{table}_school_id", table, ["school_id"])

    # ── 5. schedules tablosuna schedule_run_id FK ekle ─────────────────────
    op.add_column(
        "schedules",
        sa.Column(
            "schedule_run_id", sa.Integer(),
            sa.ForeignKey("schedule_runs.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )

    # ── 6. classrooms unique constraint güncelle ──────────────────────────
    # Eski tek sütun unique'i kaldır, composite ekle
    try:
        op.drop_constraint("classrooms_name_key", "classrooms", type_="unique")
    except Exception:
        pass  # Constraint adı farklı olabilir
    op.create_unique_constraint("uq_classroom_school_name", "classrooms", ["school_id", "name"])


def downgrade() -> None:
    # Composite unique constraint'i geri al
    op.drop_constraint("uq_classroom_school_name", "classrooms", type_="unique")
    try:
        op.create_unique_constraint("classrooms_name_key", "classrooms", ["name"])
    except Exception:
        pass

    # schedule_run_id kaldır
    op.drop_column("schedules", "schedule_run_id")

    # school_id kaldır
    for table in ("schedules", "teacher_courses", "courses", "classrooms", "teachers"):
        op.drop_index(f"ix_{table}_school_id", table)
        op.drop_column(table, "school_id")

    # Yeni tabloları kaldır
    op.drop_table("pdf_files")
    op.drop_table("schedule_runs")
    op.drop_table("user_school_memberships")
