# Ders Programı Oluşturucu (Schedule Service)

Okul idarecileri için otomatik haftalık ders programı oluşturma sistemi.

## Hızlı Başlangıç (Docker)

```bash
# Ortam değişkenlerini ayarla
cp .env.example .env

# Servisi başlat
docker-compose up -d --build

# Migration çalıştır
docker-compose exec api alembic upgrade head
```

API: http://localhost:8000
Swagger Docs: http://localhost:8000/docs

## Yerel Geliştirme

```bash
# Bağımlılıkları yükle
pip install -r requirements.txt

# PostgreSQL veritabanı olmalı (.env dosyasını düzenle)
# Migration çalıştır
alembic upgrade head

# Sunucuyu başlat
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| POST | `/api/v1/teachers/` | Öğretmen ekle |
| POST | `/api/v1/teachers/upload` | CSV/Excel ile toplu yükleme |
| POST | `/api/v1/teachers/{id}/unavailabilities` | Müsait olmama kaydı ekle |
| POST | `/api/v1/classrooms/` | Sınıf ekle |
| POST | `/api/v1/courses/` | Ders ekle |
| POST | `/api/v1/schedules/generate` | Otomatik program oluştur |
| GET | `/api/v1/schedules/{id}/pdf/{classroom_id}` | Sınıf PDF indir |
| GET | `/api/v1/schedules/{id}/pdf` | Tüm PDF linkleri |

Detaylı API dökümantasyonu: http://localhost:8000/docs

## Klasör Yapısı

```
schedule-service/
├── app/
│   ├── main.py          # FastAPI app
│   ├── config.py         # Ayarlar
│   ├── database.py       # SQLAlchemy
│   ├── models/           # DB modelleri
│   ├── schemas/          # Pydantic şemaları
│   ├── routers/          # API endpoint'leri
│   ├── services/         # PDF üretimi
│   └── algorithms/       # OR-Tools zamanlama
├── alembic/              # DB migration
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```
