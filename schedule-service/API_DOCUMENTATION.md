# Ders Programı API — Flutter Entegrasyon Dokümanı

**Base URL**: `https://api.dovizlens.online`  
**Version**: `2.0.0`

---

## Tüm Requestlerde Zorunlu Headerlar

```
Authorization: Bearer <supabase_access_token>
X-School-Id: <school_id>
Content-Type: application/json
```

### Flutter'da header oluşturma

```dart
final session = Supabase.instance.client.auth.currentSession;
final token = session?.accessToken;

final headers = {
  'Authorization': 'Bearer $token',
  'X-School-Id': '$schoolId',
  'Content-Type': 'application/json',
};
```

### Hata Kodları

| Kod | Anlam |
|-----|-------|
| `401` | Token eksik veya geçersiz |
| `403` | Bu okula erişim yetkisi yok |
| `400` | X-School-Id header eksik |
| `404` | Kayıt bulunamadı |
| `409` | Kayıt zaten mevcut (duplicate) |
| `422` | Validasyon hatası veya çözüm bulunamadı |

---

## 1. Öğretmenler

### GET `/api/v1/teachers/`

Öğretmenleri listele.

**Request:**
```
GET /api/v1/teachers/?skip=0&limit=100
```

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Ahmet Yılmaz",
    "max_daily_hours": 6,
    "unavailable_times": [
      {"day": 0, "hour": 1},
      {"day": 2, "hour": 5}
    ]
  },
  {
    "id": 2,
    "name": "Fatma Demir",
    "max_daily_hours": 8,
    "unavailable_times": []
  }
]
```

---

### POST `/api/v1/teachers/`

Yeni öğretmen ekle.

**Request Body:**
```json
{
  "name": "Ahmet Yılmaz",
  "max_daily_hours": 6,
  "unavailable_times": [
    {"day": 0, "hour": 1},
    {"day": 2, "hour": 5}
  ]
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `name` | string | ✅ | Öğretmen adı (1-200 karakter) |
| `max_daily_hours` | int | ❌ | Günlük max ders saati (1-8, varsayılan: 8) |
| `unavailable_times` | array | ❌ | Müsait olmadığı saatler |
| `unavailable_times[].day` | int | ✅ | Gün (0=Pazartesi, 4=Cuma) |
| `unavailable_times[].hour` | int | ✅ | Saat (1-8) |

**Response (201):**
```json
{
  "id": 1,
  "name": "Ahmet Yılmaz",
  "max_daily_hours": 6,
  "unavailable_times": [
    {"day": 0, "hour": 1},
    {"day": 2, "hour": 5}
  ]
}
```

---

### POST `/api/v1/teachers/upload`

Excel/CSV ile toplu öğretmen yükleme.

**Request:** `multipart/form-data`
```
Content-Type: multipart/form-data
file: <teachers.xlsx veya teachers.csv>
```

Flutter:
```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/v1/teachers/upload'),
);
request.headers.addAll(headers);
request.files.add(await http.MultipartFile.fromPath('file', filePath));
final response = await request.send();
```

Beklenen sütunlar: `name` (zorunlu), `max_daily_hours` (opsiyonel)

**Response (200):**
```json
{
  "message": "5 öğretmen başarıyla yüklendi",
  "saved_count": 5,
  "error_count": 1,
  "saved": [
    {"id": 1, "name": "Ahmet Yılmaz", "max_daily_hours": 8},
    {"id": 2, "name": "Fatma Demir", "max_daily_hours": 6}
  ],
  "errors": [
    {"row": 4, "error": "'name' alanı boş"}
  ]
}
```

---

## 2. Sınıflar

### GET `/api/v1/classrooms/`

**Request:**
```
GET /api/v1/classrooms/?skip=0&limit=100
```

**Response (200):**
```json
[
  {"id": 1, "name": "9-A", "grade_level": 9},
  {"id": 2, "name": "9-B", "grade_level": 9},
  {"id": 3, "name": "10-A", "grade_level": 10}
]
```

---

### POST `/api/v1/classrooms/`

**Request Body:**
```json
{
  "name": "9-A",
  "grade_level": 9
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `name` | string | ✅ | Sınıf adı (1-100 karakter, okul içinde unique) |
| `grade_level` | int | ✅ | Sınıf seviyesi (1-12) |

**Response (201):**
```json
{
  "id": 1,
  "name": "9-A",
  "grade_level": 9
}
```

**Hata (409):**
```json
{"detail": "Bu sınıf adı zaten mevcut"}
```

---

## 3. Dersler

### GET `/api/v1/courses/`

**Request:**
```
GET /api/v1/courses/?skip=0&limit=100
```

**Response (200):**
```json
[
  {
    "id": 1,
    "name": "Matematik",
    "weekly_hours": 5,
    "classroom_id": 1,
    "classroom_name": "9-A"
  },
  {
    "id": 2,
    "name": "Fizik",
    "weekly_hours": 3,
    "classroom_id": 1,
    "classroom_name": "9-A"
  }
]
```

---

### POST `/api/v1/courses/`

**Request Body:**
```json
{
  "name": "Matematik",
  "weekly_hours": 5,
  "classroom_id": 1
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `name` | string | ✅ | Ders adı (1-200 karakter) |
| `weekly_hours` | int | ✅ | Haftalık ders saati (1-40) |
| `classroom_id` | int | ✅ | Hangi sınıfa ait (sınıf ID) |

**Response (201):**
```json
{
  "id": 1,
  "name": "Matematik",
  "weekly_hours": 5,
  "classroom_id": 1,
  "classroom_name": "9-A"
}
```

---

## 4. Öğretmen-Ders Eşleştirme

### POST `/api/v1/teacher-courses/`

**Request Body:**
```json
{
  "teacher_id": 1,
  "course_id": 1
}
```

**Response (201):**
```json
{
  "teacher_id": 1,
  "course_id": 1,
  "teacher_name": "Ahmet Yılmaz",
  "course_name": "Matematik"
}
```

### GET `/api/v1/teacher-courses/`

**Response (200):**
```json
[
  {
    "teacher_id": 1,
    "course_id": 1,
    "teacher_name": "Ahmet Yılmaz",
    "course_name": "Matematik"
  }
]
```

---

## 5. Program Üretimi (Schedule Runs)

### POST `/api/v1/schedule-runs/`

Yeni ders programı oluştur. OR-Tools CP-SAT solver çalıştırır.

**Request:** Body yok — sadece header'lar yeterli.

```
POST /api/v1/schedule-runs/
Authorization: Bearer <token>
X-School-Id: 1
```

**Response (201) — Başarılı:**
```json
{
  "success": true,
  "message": "Ders programı başarıyla oluşturuldu (optimal). Toplam 120 ders slotu atandı.",
  "schedule_run_id": 1,
  "status": "completed",
  "created_at": "2026-03-05T20:10:00.000000",
  "total_entries": 120,
  "classrooms": [
    {"classroom_id": 1, "classroom_name": "9-A", "lesson_count": 40},
    {"classroom_id": 2, "classroom_name": "9-B", "lesson_count": 40},
    {"classroom_id": 3, "classroom_name": "10-A", "lesson_count": 40}
  ]
}
```

**Response (422) — Çözüm bulunamadı:**
```json
{
  "detail": "Ders programı oluşturulamadı. Olası nedenler:\n• Öğretmen müsaitlik saatleri yetersiz\n• Haftalık ders saatleri mevcut slotlardan fazla\n• Günlük maksimum ders saati çok düşük\nLütfen verileri kontrol edip tekrar deneyin."
}
```

---

### GET `/api/v1/schedule-runs/`

Tüm program versiyonlarını listele.

**Response (200):**
```json
[
  {"id": 2, "created_at": "2026-03-05T21:00:00", "status": "completed"},
  {"id": 1, "created_at": "2026-03-05T20:00:00", "status": "completed"}
]
```

---

### GET `/api/v1/schedule-runs/{run_id}`

Run detayı.

**Response (200):**
```json
{
  "id": 1,
  "school_id": 1,
  "created_by_user_id": "a1b2c3d4-...",
  "created_at": "2026-03-05T20:00:00",
  "status": "completed",
  "meta": {
    "initiated_at": "2026-03-05T20:00:00",
    "completed_at": "2026-03-05T20:00:05",
    "total_entries": 120
  }
}
```

---

### POST `/api/v1/schedule-runs/{run_id}/pdf`

Belirtilen run için sınıf bazlı PDF üret.

**Request:**
```
POST /api/v1/schedule-runs/1/pdf?school_name=Anadolu%20Lisesi
```

| Query Param | Tip | Zorunlu | Açıklama |
|-------------|-----|---------|----------|
| `school_name` | string | ❌ | PDF başlığı (varsayılan: "Okul Adı") |

**Response (201):**
```json
{
  "success": true,
  "schedule_run_id": 1,
  "message": "3 sınıf için PDF oluşturuldu",
  "pdfs": [
    {
      "classroom_id": 1,
      "classroom_name": "9-A",
      "file_url": "/files/1/1/9-A.pdf",
      "lesson_count": 40
    },
    {
      "classroom_id": 2,
      "classroom_name": "9-B",
      "file_url": "/files/1/1/9-B.pdf",
      "lesson_count": 40
    },
    {
      "classroom_id": 3,
      "classroom_name": "10-A",
      "file_url": "/files/1/1/10-A.pdf",
      "lesson_count": 40
    }
  ]
}
```

---

## 6. Dosya İndirme

### GET `/files/{school_id}/{schedule_run_id}/{filename}`

PDF dosyasını indir.

**Request:**
```
GET /files/1/1/9-A.pdf
Authorization: Bearer <token>
X-School-Id: 1
```

**Response:** PDF binary (application/pdf)

**Güvenlik:**
- Authorization zorunlu
- X-School-Id ile path'deki school_id eşleşmeli
- Başka okulun dosyasına erişim → 403

---

## Flutter Örnek Servis Sınıfı

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleApi {
  static const _baseUrl = 'https://api.dovizlens.online';
  final int schoolId;

  ScheduleApi({required this.schoolId});

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Authorization': 'Bearer $token',
      'X-School-Id': '$schoolId',
      'Content-Type': 'application/json',
    };
  }

  // ─── Teachers ────────────────────────────
  Future<List<dynamic>> getTeachers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/teachers/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createTeacher(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/teachers/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  // ─── Classrooms ──────────────────────────
  Future<List<dynamic>> getClassrooms() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/classrooms/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createClassroom(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/classrooms/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  // ─── Courses ─────────────────────────────
  Future<List<dynamic>> getCourses() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/courses/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/courses/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  // ─── Schedule Runs ───────────────────────
  Future<Map<String, dynamic>> generateSchedule() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/schedule-runs/'),
      headers: _headers,
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getScheduleRuns() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/schedule-runs/'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> generatePdf(int runId, String schoolName) async {
    final uri = Uri.parse('$_baseUrl/api/v1/schedule-runs/$runId/pdf')
        .replace(queryParameters: {'school_name': schoolName});
    final res = await http.post(uri, headers: _headers);
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  // ─── File Download ───────────────────────
  String getPdfUrl(String filePath) => '$_baseUrl/files/$filePath';
}
```

---

## Deployment

```bash
# 1. .env dosyasına SUPABASE_JWT_SECRET ekleyin
# 2. Build & run
docker-compose build
docker-compose up -d
# 3. Migration
docker-compose exec api alembic upgrade head
# 4. İlk admin kaydı
docker-compose exec db psql -U postgres -d schedule_db -c \
  "INSERT INTO user_school_memberships (user_id, school_id, role) VALUES ('supabase-uuid', 1, 'admin');"
```
