"""
ReportLab ile sınıf bazlı haftalık ders programı PDF oluşturma.
"""

import os
from datetime import datetime, timezone

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer

DAY_NAMES = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"]
FILES_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "files")


def _ensure_dir():
    os.makedirs(FILES_DIR, exist_ok=True)


def generate_classroom_pdf(
    classroom_name: str,
    school_name: str,
    entries: list[dict],
    num_periods: int = 8,
) -> tuple[str, str]:
    """
    Bir sınıf için haftalık ders programı PDF'i oluşturur.

    entries: [{day, hour, course_name, teacher_name}, ...]

    Returns: (dosya_yolu, dosya_adı)
    """
    _ensure_dir()

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    safe_name = classroom_name.replace(" ", "_").replace("/", "_")
    filename = f"program_{safe_name}_{timestamp}.pdf"
    filepath = os.path.join(FILES_DIR, filename)

    doc = SimpleDocTemplate(
        filepath,
        pagesize=landscape(A4),
        topMargin=1.5 * cm,
        bottomMargin=1 * cm,
        leftMargin=1.5 * cm,
        rightMargin=1.5 * cm,
    )

    styles = getSampleStyleSheet()

    school_style = ParagraphStyle(
        "SchoolTitle",
        parent=styles["Heading1"],
        fontSize=18,
        alignment=1,
        spaceAfter=2,
        textColor=colors.HexColor("#2c3e50"),
    )
    title_style = ParagraphStyle(
        "ClassTitle",
        parent=styles["Heading2"],
        fontSize=14,
        alignment=1,
        spaceAfter=4,
        textColor=colors.HexColor("#34495e"),
    )
    subtitle_style = ParagraphStyle(
        "Subtitle",
        parent=styles["Normal"],
        fontSize=9,
        alignment=1,
        spaceAfter=12,
        textColor=colors.grey,
    )
    cell_style = ParagraphStyle(
        "CellStyle",
        parent=styles["Normal"],
        fontSize=8,
        alignment=1,
        leading=10,
    )

    # ── Grid: satırlar=saat, sütunlar=gün ──────────────────────────────────
    grid: dict[tuple[int, int], str] = {}
    for entry in entries:
        d = entry["day"]
        p = entry["hour"]
        course = entry.get("course_name", "")
        teacher = entry.get("teacher_name", "")
        cell_text = (
            f"{course}<br/><font size=7 color='grey'>{teacher}</font>"
            if teacher
            else course
        )
        grid[(d, p)] = cell_text

    # ── Tablo verisi ───────────────────────────────────────────────────────
    header_row = ["Saat"] + DAY_NAMES
    table_data = [header_row]

    for p in range(1, num_periods + 1):
        row = [f"{p}. Ders"]
        for d in range(5):
            cell_content = grid.get((d, p), "")
            if cell_content:
                row.append(Paragraph(cell_content, cell_style))
            else:
                row.append("")
        table_data.append(row)

    col_widths = [2.5 * cm] + [4.8 * cm] * 5

    table = Table(table_data, colWidths=col_widths, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                # Header
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2c3e50")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTSIZE", (0, 0), (-1, 0), 10),
                ("ALIGN", (0, 0), (-1, 0), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 10),
                ("TOPPADDING", (0, 0), (-1, 0), 10),
                # Saat sütunu
                ("BACKGROUND", (0, 1), (0, -1), colors.HexColor("#ecf0f1")),
                ("FONTSIZE", (0, 1), (0, -1), 9),
                ("ALIGN", (0, 1), (0, -1), "CENTER"),
                # Grid çizgileri
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#bdc3c7")),
                ("ALIGN", (1, 1), (-1, -1), "CENTER"),
                # Alternatif satır rengi
                *[
                    ("BACKGROUND", (1, r), (-1, r), colors.HexColor("#f8f9fa"))
                    for r in range(2, num_periods + 1, 2)
                ],
                # Padding
                ("TOPPADDING", (0, 1), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 1), (-1, -1), 8),
            ]
        )
    )

    now_str = datetime.now(timezone.utc).strftime("%d.%m.%Y %H:%M")

    elements = [
        Paragraph(school_name, school_style),
        Paragraph(f"{classroom_name} — Haftalık Ders Programı", title_style),
        Paragraph(f"Oluşturulma: {now_str}", subtitle_style),
        Spacer(1, 0.3 * cm),
        table,
    ]

    doc.build(elements)
    return filepath, filename
