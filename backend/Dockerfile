# Start from an official slim Python image (small, but has the basics)
FROM python:3.11-slim

# Prevents Python from buffering output, so logs show up immediately on Render
ENV PYTHONUNBUFFERED=1
# Prevents Python from writing .pyc cache files (not needed in a container)
ENV PYTHONDONTWRITEBYTECODE=1

# Set the working directory inside the container — all following commands run from here
WORKDIR /app

# Install system-level dependencies:
# - binutils, gdal-bin, libgdal-dev: required for django.contrib.gis (GeoDjango) to work
# - libpq-dev: required to build psycopg2 (PostgreSQL driver) if not using the binary wheel
# - postgresql-client: optional, but useful for debugging DB connections from inside the container
RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    gdal-bin \
    libgdal-dev \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Tell GeoDjango exactly where GDAL/GEOS are, since on Debian they're not always
# auto-detected the way they are on Mac/Windows installs
ENV GDAL_LIBRARY_PATH=/usr/lib/libgdal.so
ENV GEOS_LIBRARY_PATH=/usr/lib/libgeos_c.so

# Copy only requirements.txt first (not the whole project yet) — this lets Docker
# cache this layer, so re-builds are much faster if your code changes but
# dependencies don't
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of your backend project into the container
COPY . .

# Collect static files (Django admin CSS/JS etc.) into STATIC_ROOT, so they can be served
# Using --noinput so it doesn't hang waiting for confirmation during build
RUN python manage.py collectstatic --noinput

# Render sets the PORT environment variable dynamically; gunicorn must bind to it.
# config.wsgi:application points to backend/config/wsgi.py's "application" object.
CMD gunicorn config.wsgi:application --bind 0.0.0.0:$PORT