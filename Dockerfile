# Use a stable, secure Python version (latest 3.11.x)
FROM python:3.11-slim-bookworm

# set work directory
WORKDIR /app

# Install system dependencies with pinned versions for reproducibility
RUN apt-get update && apt-get install --no-install-recommends -y \
    dnsutils=1:9.18.24-1~deb12u1 \
    libpq-dev=15.6-0+deb12u1 \
    gcc=4:12.2.0-3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONFAULTHANDLER=1
ENV PYTHONHASHSEED=random
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Upgrade pip and install dependencies
COPY requirements.txt .
RUN python -m pip install --upgrade pip==24.0
RUN pip install --no-cache-dir -r requirements.txt

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# copy project
COPY --chown=appuser:appuser . /app/

# Run migrations and collect static files if needed
RUN python3 manage.py migrate --no-input

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "4", "--worker-class", "gthread", "pygoat.wsgi"]
