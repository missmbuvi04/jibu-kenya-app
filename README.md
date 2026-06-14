# Jibu Kenya — Civic Infrastructure Reporting Platform

## Description
Jibu Kenya is a digital civic infrastructure reporting and accountability platform 
designed for Kenya's 47-county devolved governance structure. Citizens can submit 
GPS-tagged, photo-evidenced infrastructure failure reports (roads, water, bridges, 
streetlights, public facilities) which are automatically routed to the correct county 
department or police station. The system includes duplicate detection, real-time status 
tracking, role-based access control, and a full audit trail.

**GitHub Repository:** [https://github.com/missmbuvi04/final-mission-capstone.git]
**VideoDemo:**[https://screenrec.com/share/2qK7e9IAQt]

---

## Tech Stack
- **Backend:** Python 3.11, Django 6.0.5, Django REST Framework
- **Database:** PostgreSQL 17 with PostGIS 3.x
- **Authentication:** JWT (djangorestframework-simplejwt)
- **Cache/Queue:** Redis 7.x with Celery
- **Storage:** Object Storage (MinIO/AWS S3) for photos
- **Frontend:** Figma prototype (Flutter in development)
- **Docs:** Swagger UI / ReDoc

---

## Setup Instructions

### Prerequisites
- Python 3.11+
- PostgreSQL 17 with PostGIS extension
- Redis
- Git

### Steps

1. **Clone the repository**

git clone https://github.com/missmbuvi04/final-mission-capstone.git
cd final-mission-capstone

2. **Create and activate virtual environment**
python -m venv venv
venv\Scripts\activate

3. **Install dependencies**
pip install -r requirements.txt

4. **Create a .env file** in the root directory with:
SECRET_KEY=your-secret-key
DB_NAME=jibu_kenya
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

5. **Set up the database**
   - Create a PostgreSQL database named `jibu_kenya`
   - Enable PostGIS: `CREATE EXTENSION postgis;`

6. **Run migrations**
python manage.py migrate

7. **Create a superuser**
python manage.py createsuperuser

8. **Run the server**
python manage.py runserver

9. **Access API documentation** at `http://localhost:8000/api/docs/`

---

## Designs
- Figma Prototype: [https://www.figma.com/design/JOWjkSm2DO8CzWJSqt7E8d/Jibu-Kenya-%E2%80%94-UI-Design?node-id=0-1&m=dev&t=HPPROIpnEXiMgHDp-1]
- Screenshots: See `/designs` folder

---

## Deployment Plan
Jibu Kenya is designed for deployment on Railway or Render (free tier). 
The Django backend connects to a managed PostgreSQL instance with PostGIS enabled. 
Static files are served via WhiteNoise and media files (photos) are stored in an 
external S3-compatible object storage bucket. HTTPS is automatically provisioned 
by the platform at no cost. Environment variables are configured through the 
platform dashboard. A Procfile would be added to define the web process as 
`gunicorn config.wsgi:application`.

---

## API Endpoints
Full documentation available at `/api/docs/` (Swagger) or `/api/redoc/` (ReDoc)

Key endpoints:
- `POST /api/auth/register/` — Register new user
- `POST /api/auth/login/` — Login and get JWT token
- `POST /api/reports/` — Submit infrastructure report
- `GET /api/reports/` — List reports (role-filtered)
- `PATCH /api/reports/{id}/status/` — Update report status
- `GET /api/audit/` — View audit logs (admin only)
