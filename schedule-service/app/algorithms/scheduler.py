"""
OR-Tools CP-SAT tabanlı ders programı oluşturucu.

Karar değişkeni: x[tc, d, p] ∈ {0, 1}
  tc = (teacher_id, course_id) çifti (TeacherCourse kaydı)
  d  = gün (0=Pazartesi … 4=Cuma)
  p  = ders saati (1 … MAX_PERIODS)
  1 ise → bu öğretmen bu dersi d günü p. saatte işler.

Hard Constraints:
  H1  Her dersin weekly_hours kadar slot'a atanması
  H2  Bir sınıf aynı (d, p)'de en fazla bir ders alır
  H3  Bir öğretmen aynı (d, p)'de en fazla bir ders verir
  H4  Öğretmen unavailable_times'daki slotlara atanamaz
  H5  Öğretmenin günlük toplam ders saati max_daily_hours'u aşmaz

Soft Constraints (Objective — minimize):
  S1  Derslerin günlere dengeli dağılımı  (max−min spread)
  S2  Aynı ders mümkünse blok (ardışık saatler) şeklinde verilsin
"""

from __future__ import annotations

from dataclasses import dataclass, field
from ortools.sat.python import cp_model
from sqlalchemy.orm import Session, joinedload

from app.models.teacher import Teacher
from app.models.classroom import Classroom
from app.models.course import Course
from app.models.teacher_course import TeacherCourse
from app.models.schedule import Schedule
from app.config import settings


# ───────────────────────────── Result ──────────────────────────────────────

@dataclass
class ScheduleResult:
    success: bool
    entries: list[dict] = field(default_factory=list)
    # Her entry: {classroom_id, teacher_id, course_id, day, hour}
    message: str = ""


# ───────────────────────────── Ana Fonksiyon ──────────────────────────────

def generate_schedule(db_session: Session) -> ScheduleResult:
    """
    Veritabanındaki tüm Teacher, Course, TeacherCourse verilerini okur
    ve CP-SAT ile çakışmasız, dengeli bir haftalık program üretir.
    """

    num_days: int = settings.DAYS_PER_WEEK       # 5
    num_periods: int = settings.MAX_PERIODS_PER_DAY  # 8

    # ── 1. Verileri yükle ──────────────────────────────────────────────────
    teachers: list[Teacher] = db_session.query(Teacher).all()
    courses: list[Course] = (
        db_session.query(Course)
        .options(joinedload(Course.classroom))
        .all()
    )
    assignments: list[TeacherCourse] = db_session.query(TeacherCourse).all()

    if not teachers:
        return ScheduleResult(False, [], "Hiç öğretmen tanımlanmamış.")
    if not courses:
        return ScheduleResult(False, [], "Hiç ders tanımlanmamış.")
    if not assignments:
        return ScheduleResult(False, [], "Hiç öğretmen-ders eşleştirmesi yapılmamış.")

    # Hızlı erişim tabloları
    teacher_map: dict[int, Teacher] = {t.id: t for t in teachers}
    course_map: dict[int, Course] = {c.id: c for c in courses}

    # Unavailable set: {(teacher_id, day, hour)}
    unavailable: set[tuple[int, int, int]] = set()
    for t in teachers:
        if t.unavailable_times:
            for slot in t.unavailable_times:
                unavailable.add((t.id, slot["day"], slot["hour"]))

    # Her ders için atanmış öğretmen(ler) — birden fazla olabilir, solver seçer
    # Ancak basit durumda her ders tek öğretmene atanmış olabilir
    course_teachers: dict[int, list[int]] = {}
    for a in assignments:
        course_teachers.setdefault(a.course_id, []).append(a.teacher_id)

    # Her dersin weekly_hours > 0 ve atanmış öğretmeni olmalı
    active_pairs: list[tuple[int, int, int]] = []  # (index, teacher_id, course_id)
    pair_index = 0
    pair_to_idx: dict[tuple[int, int], int] = {}

    for course in courses:
        t_ids = course_teachers.get(course.id, [])
        if not t_ids:
            continue
        for t_id in t_ids:
            pair_to_idx[(t_id, course.id)] = pair_index
            active_pairs.append((pair_index, t_id, course.id))
            pair_index += 1

    if not active_pairs:
        return ScheduleResult(False, [], "Aktif öğretmen-ders eşleştirmesi bulunamadı.")

    days = range(num_days)
    periods = range(1, num_periods + 1)

    # ── 2. Model ───────────────────────────────────────────────────────────
    model = cp_model.CpModel()

    # x[idx, d, p] = 1 → pair idx, d günü p. saatte ders işler
    x: dict[tuple[int, int, int], cp_model.IntVar] = {}
    for idx, t_id, c_id in active_pairs:
        for d in days:
            for p in periods:
                x[(idx, d, p)] = model.new_bool_var(f"x_{idx}_d{d}_p{p}")

    # Eğer bir dersin birden fazla öğretmeni varsa:
    # Hangi öğretmenin hangi slotu vereceğini seçmek için
    # y[course_id, d, p] = kimin girdiğini belirler (dolaylı, x üzerinden)

    # ── 3. Hard Constraints ────────────────────────────────────────────────

    # H1: Her dersin weekly_hours kadar slot'a atanması
    # Bir dersin birden fazla öğretmeni varsa, toplamları weekly_hours olmalı
    courses_by_id: dict[int, list[int]] = {}  # course_id → [pair_idx, ...]
    for idx, t_id, c_id in active_pairs:
        courses_by_id.setdefault(c_id, []).append(idx)

    for c_id, pair_indices in courses_by_id.items():
        course = course_map[c_id]
        model.add(
            sum(x[(idx, d, p)] for idx in pair_indices for d in days for p in periods)
            == course.weekly_hours
        )

    # H2: Bir sınıf aynı (d, p)'de en fazla bir ders alır
    classroom_pairs: dict[int, list[int]] = {}  # classroom_id → [pair_idx, ...]
    for idx, t_id, c_id in active_pairs:
        cl_id = course_map[c_id].classroom_id
        classroom_pairs.setdefault(cl_id, []).append(idx)

    for cl_id, pair_indices in classroom_pairs.items():
        for d in days:
            for p in periods:
                model.add(sum(x[(idx, d, p)] for idx in pair_indices) <= 1)

    # H3: Bir öğretmen aynı (d, p)'de en fazla bir ders verir
    teacher_pairs: dict[int, list[int]] = {}  # teacher_id → [pair_idx, ...]
    for idx, t_id, c_id in active_pairs:
        teacher_pairs.setdefault(t_id, []).append(idx)

    for t_id, pair_indices in teacher_pairs.items():
        for d in days:
            for p in periods:
                model.add(sum(x[(idx, d, p)] for idx in pair_indices) <= 1)

    # H4: Öğretmen unavailable slotlara atanamaz
    for idx, t_id, c_id in active_pairs:
        for d in days:
            for p in periods:
                if (t_id, d, p) in unavailable:
                    model.add(x[(idx, d, p)] == 0)

    # H5: Öğretmenin günlük toplam ders saati max_daily_hours'u aşmaz
    for t_id, pair_indices in teacher_pairs.items():
        teacher = teacher_map[t_id]
        for d in days:
            model.add(
                sum(x[(idx, d, p)] for idx in pair_indices for p in periods)
                <= teacher.max_daily_hours
            )

    # ── 4. Soft Constraints ────────────────────────────────────────────────
    penalties: list[cp_model.IntVar] = []

    # S1: Derslerin günlere dengeli dağılımı (max - min spread)
    for c_id, pair_indices in courses_by_id.items():
        course = course_map[c_id]
        if course.weekly_hours <= 1:
            continue

        daily_counts = []
        for d in days:
            v = model.new_int_var(0, num_periods, f"daily_c{c_id}_d{d}")
            model.add(v == sum(x[(idx, d, p)] for idx in pair_indices for p in periods))
            daily_counts.append(v)

        mx = model.new_int_var(0, num_periods, f"max_c{c_id}")
        mn = model.new_int_var(0, num_periods, f"min_c{c_id}")
        model.add_max_equality(mx, daily_counts)
        model.add_min_equality(mn, daily_counts)

        spread = model.new_int_var(0, num_periods, f"spread_c{c_id}")
        model.add(spread == mx - mn)
        # Ağırlık: 2 (dengeli dağılım önemli)
        penalties.append(2 * spread)

    # S2: Aynı ders blok (ardışık saat) olarak verilsin
    # Ardışık olmayan geçişlere ceza ver
    # gap[idx, d, p] = x[idx,d,p] - x[idx,d,p+1] farkının mutlak değeri
    for c_id, pair_indices in courses_by_id.items():
        course = course_map[c_id]
        if course.weekly_hours <= 1:
            continue

        for idx in pair_indices:
            for d in days:
                for p in range(1, num_periods):  # p, p+1 ardışık
                    # x[p]=1, x[p+1]=0 → boşluk → ceza
                    gap = model.new_bool_var(f"gap_{idx}_d{d}_p{p}")
                    # gap = 1 iff x[idx,d,p]=1 AND x[idx,d,p+1]=0
                    # Yani: ders var ama bir sonraki saatte yok (ve sonrasında tekrar var olabilir)
                    # Basitleştirilmiş: ardışık olmama sayısını minimize et
                    diff = model.new_int_var(-1, 1, f"diff_{idx}_d{d}_p{p}")
                    model.add(diff == x[(idx, d, p)] - x[(idx, d, p + 1)])
                    abs_diff = model.new_int_var(0, 1, f"abs_{idx}_d{d}_p{p}")
                    model.add_abs_equality(abs_diff, diff)
                    # Ağırlık: 1 (blok az önemli, dengeden sonra)
                    penalties.append(abs_diff)

    if penalties:
        model.minimize(sum(penalties))

    # ── 5. Solver ──────────────────────────────────────────────────────────
    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = 120
    solver.parameters.num_workers = 8
    solver.parameters.log_search_progress = False

    status = solver.solve(model)

    if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        return ScheduleResult(
            False,
            [],
            "Ders programı oluşturulamadı. Olası nedenler:\n"
            "• Öğretmen müsaitlik saatleri yetersiz\n"
            "• Haftalık ders saatleri mevcut slotlardan fazla\n"
            "• Günlük maksimum ders saati çok düşük\n"
            "Lütfen verileri kontrol edip tekrar deneyin.",
        )

    # ── 6. Çözümü çıkar ───────────────────────────────────────────────────
    entries: list[dict] = []
    for idx, t_id, c_id in active_pairs:
        course = course_map[c_id]
        for d in days:
            for p in periods:
                if solver.value(x[(idx, d, p)]) == 1:
                    entries.append({
                        "classroom_id": course.classroom_id,
                        "teacher_id": t_id,
                        "course_id": c_id,
                        "day": d,
                        "hour": p,
                    })

    status_label = "optimal" if status == cp_model.OPTIMAL else "feasible"
    return ScheduleResult(
        success=True,
        entries=entries,
        message=(
            f"Ders programı başarıyla oluşturuldu ({status_label}). "
            f"Toplam {len(entries)} ders slotu atandı."
        ),
    )
