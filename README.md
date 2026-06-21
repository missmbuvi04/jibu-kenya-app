# Jibu Kenya — Civic Infrastructure Reporting Platform

> **Jibu** means *answer* or *respond* in Swahili. Built to close the gap between what Kenyan citizens can see and what their county governments can act on.

**Live Backend:** https://jibu-kenya-app.onrender.com  
**GitHub Repository:** https://github.com/missmbuvi04/jibu-kenya-app  
**Demo Video:** https://screenrec.com/share/2qK7e9IAQt  
**Figma Designs:** https://www.figma.com/design/JOWjkSm2DO8CzWJSqt7E8d/Jibu-Kenya-UI-Design

---

## What it does

Jibu Kenya is a digital civic infrastructure reporting and accountability platform designed for Kenya's 47-county devolved governance structure. Citizens submit GPS-tagged, photo-evidenced infrastructure failure reports which are automatically routed to the correct county department or police station based on report category. The system provides real-time status tracking, duplicate detection, role-based dashboards, and a full audit trail.

**Four user roles, two platform targets:**

| Role | Platform | What they do |
|---|---|---|
| Citizen | Mobile (Android APK) | Submit reports, track status, view map |
| County Officer | Web (Flutter Web) | Review reports, update status, manage departments |
| Police Officer | Mobile (Android APK) | View and action safety/crime reports |
| Administrator | Web (Flutter Web) | Manage users, departments, audit logs |

---

## Tech Stack

**Backend**
- Python 3.11 — required for GDAL/PostGIS compatibility
- Django 5.2.1 with Django REST Framework
- PostgreSQL 17 (local dev) / PostgreSQL 16 (Render deployment) with PostGIS 3.6 — spatial queries for duplicate detection
- JWT authentication via djangorestframework-simplejwt
- Python ImageHash — perceptual image hashing for duplicate photo detection
- WhiteNoise — static file serving in production
- Gunicorn — WSGI server

**Frontend**
- Flutter (single Dart codebase, two build targets)
  - Mobile (Android APK) — Citizen and Police Officer roles
  - Flutter Web — County Officer and Administrator roles
- Riverpod — state management
- Dio — HTTP client with JWT interceptor and auto-refresh
- go_router — declarative routing with role-based redirects

**Infrastructure**
- Backend deployed on Render (https://jibu-kenya-app.onrender.com)
- PostgreSQL/PostGIS managed database on Render
- Flutter Web deployed as static site on Netlify
- Android APK distributed directly for mobile roles

**Planned (not yet implemented in MVP)**
- Redis — GPS coordinate caching and async task queue
- External object storage (MinIO/S3) — currently using local filesystem for photos

---

## Duplicate Detection Pipeline

Reports are checked for duplicates in two sequential stages:

1. **Spatial proximity filter** — PostGIS `ST_DWithin` query identifies any existing reports within 100 metres of the incoming GPS coordinates
2. **Perceptual image hash comparison** — only if nearby reports are found, ImageHash computes a Hamming distance between photo hashes; reports with ≥ 85% similarity are flagged as duplicates

---

## Local Development Setup

### Prerequisites
- Python 3.11 (not 3.12 or 3.13 — GDAL has compatibility issues with newer versions)
- PostgreSQL 17 with PostGIS extension installed
- Flutter SDK (latest stable)
- Git

### Backend Setup

```bash
# 1. Clone the repository
git clone https://github.com/missmbuvi04/jibu-kenya-app.git
cd jibu-kenya-app/backend

# 2. Create and activate virtual environment using Python 3.11 explicitly
python3.11 -m venv venv

# Windows:
venv\Scripts\activate

# macOS/Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create a .env file in backend/ with:
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DB_NAME=jibu_kenya
DB_USER=postgres
DB_PASSWORD=your-postgres-password
DB_HOST=localhost
DB_PORT=5432

# 5. Create the PostgreSQL database and enable PostGIS
psql -U postgres
CREATE DATABASE jibu_kenya;
\c jibu_kenya
CREATE EXTENSION postgis;
\q

# 6. Run migrations
python manage.py migrate

# 7. Create a superuser (admin account)
python manage.py createsuperuser

# 8. Start the backend server
# For mobile testing (replace with your machine's local IP):
python manage.py runserver 0.0.0.0:8000

# For web-only testing:
python manage.py runserver
```

### Frontend Setup

```bash
cd jibu-kenya-app/frontend

# Install Flutter dependencies
flutter pub get

# Run in Chrome (County Officer and Admin web roles)
flutter run -d chrome

# Run on connected Android device (Citizen and Police Officer mobile roles)
flutter run -d <device-id>

# Build release APK (hits live Render backend)
flutter build apk --release

# Build Flutter web (hits live Render backend)
flutter build web --release
```

**Note:** The `baseUrl` in `lib/core/constants/api_constants.dart` automatically switches between:
- `http://127.0.0.1:8000` — when running in Chrome (`kIsWeb`)
- `https://jibu-kenya-app.onrender.com` — in release builds (`kReleaseMode`)
- `http://192.168.1.88:8000` — local IP for debug mobile builds (update to match your machine)

---

## API Endpoints

Base URL (production): `https://jibu-kenya-app.onrender.com`

### Authentication
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/users/register/` | Public | Register new user account |
| POST | `/api/users/login/` | Public | Login, returns JWT access + refresh tokens |
| POST | `/api/users/token/refresh/` | Public | Refresh access token |
| GET | `/api/users/profile/` | Authenticated | Get current user's profile |
| PATCH | `/api/users/profile/` | Authenticated | Update own profile |
| GET | `/api/users/all/` | Admin only | List all users |
| PATCH | `/api/users/<id>/` | Admin only | Update a specific user's role/county/status |
| DELETE | `/api/users/<id>/` | Admin only | Delete a user account |

### Reports
| Method | Endpoint | Access | Description |
|---|---|---|---|
| GET | `/api/reports/` | Authenticated | List reports (filtered by role and county) |
| POST | `/api/reports/` | Citizen | Submit new infrastructure report |
| POST | `/api/reports/status/` | Officers | Update report status with notes |
| GET | `/api/reports/duplicates/` | Admin | List flagged duplicate reports |

### Departments
| Method | Endpoint | Access | Description |
|---|---|---|---|
| GET | `/api/departments/` | Officers + Admin | List active departments |
| POST | `/api/departments/` | Admin only | Create new department |
| PATCH | `/api/departments/<id>/` | Admin only | Update department details |
| DELETE | `/api/departments/<id>/` | Admin only | Delete a department |

### Audit and Notifications
| Method | Endpoint | Access | Description |
|---|---|---|---|
| GET | `/api/audit/` | Admin only | View full audit log of all system events |
| GET | `/api/notifications/` | Authenticated | Get notifications for current user |
| PATCH | `/api/notifications/<id>/` | Authenticated | Mark notification as read |

---

## Project Structure

```
jibu-kenya-app/
├── backend/                    # Django REST API
│   ├── config/                 # Settings, URLs, WSGI, Dockerfile
│   ├── users/                  # Auth, registration, role management
│   │   └── tests.py            # Unit + integration tests
│   ├── reports/                # Report model, routing, duplicate detection
│   │   └── tests.py            # Unit + integration tests
│   ├── departments/            # County department management
│   ├── notifications/          # User notifications on status changes
│   └── audit/                  # Immutable audit log
│
└── frontend/                   # Flutter cross-platform app
    └── lib/
        ├── core/               # Constants, routing, network, storage
        └── features/
            ├── auth/           # Login, registration, JWT management
            └── reports/        # All four role screens and providers
```
---

## Deployment

**Backend** is deployed on Render as a Docker-based web service:
- `python manage.py migrate` runs automatically on every container start
- Superuser is created automatically via environment variables on first boot
- Static files served via WhiteNoise
- Environment variables configured via Render dashboard

**Mobile** (Citizen + Police Officer) — distributed as a release APK built with `flutter build apk --release`

**Web** (County Officer + Admin) — deployed as a static Flutter web build on Netlify via `flutter build web --release`

---

## Test Accounts (Production)
The following accounts exist on the live Render deployment for testing purposes:

| Role | Email | Password |
|---|---|---|
| County Officer | co1@jibutest.com | Testing1234! |
| County Officer | co2@jibutest.com | Testing1234! |
| County Officer | co3@jibutest.com | Testing1234! |
| Police Officer | po1@jibutest.com | Testing1234! |
| Police Officer | po2@jibutest.com | Testing1234! |
| Admin | admin1@jibutest.com | Testing1234! |
| Admin | admin2@jibutest.com | Testing1234! |
| Citizen | Register directly in the app | — |

## Testing

### Automated Tests — 12 tests across two strategies

```bash
cd backend
python manage.py test users.tests reports.tests --verbosity=2
```

**Unit Tests (7):**
- Registration rejects duplicate emails and weak passwords
- Login returns JWT tokens with valid credentials
- Wrong password returns HTTP 401
- Unauthenticated requests to protected endpoints are blocked
- Safety reports route automatically to police departments
- Road reports route automatically to public works departments

**Integration Tests (5):**
- Admin can access user list; citizen is forbidden
- Citizen can submit a report end to end
- Officer cannot submit reports (citizen role only)
- Citizens only see their own reports
- Officer can update report status; citizen cannot

### Usability Testing
- 10–15 participants across all four roles
- System Usability Scale (SUS) questionnaire — target score ≥ 71
- Task performance protocol with timed task completion measurement
- Post-session open-ended feedback

---

## Known Limitations (MVP Scope)

- Photos are stored on the server's local filesystem — will not persist across Render restarts on the free tier. External object storage (S3/MinIO) is the documented next step.
- Redis caching for GPS coordinate optimisation is designed in the architecture but not yet implemented.
- The free tier Render backend spins down after 15 minutes of inactivity; the first request after idle takes approximately 60 seconds to respond.
- Usability testing was conducted with participants simulating roles using synthetic data representative of Nairobi County.

---

## Ethical Compliance

No real citizen data, county government data, or police data was collected, processed, or stored at any stage of this project. All test reports used fictitious scenarios and coordinates. The system was designed in compliance with Kenya's Data Protection Act 2019 principles. See the full capstone report for ethical approval documentation.

---

## Author

**Maureen Mbuvi**  
BSc. Software Engineering  
African Leadership University  
Supervisor: Neza David Tuyishimire