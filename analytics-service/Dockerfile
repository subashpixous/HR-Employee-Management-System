# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 — build the Python environment (dlib is compiled here)
# ============================================================
FROM python:3.11-slim AS build

# build-essential + cmake are required to compile dlib (face_recognition dep).
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential cmake \
 && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /tmp/requirements.txt
# Install CPU-only torch first: easyocr depends on torch, and the default
# PyPI wheels bundle CUDA, adding multiple GB to the image for nothing.
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu \
 && pip install --no-cache-dir -r /tmp/requirements.txt

# ============================================================
# Stage 2 — slim runtime
# ============================================================
FROM python:3.11-slim AS runtime
WORKDIR /app

# tesseract-ocr for pytesseract, libglib/libgl for OpenCV, curl for the
# container healthcheck. Non-root user with a home dir (EasyOCR caches
# its models under ~/.EasyOCR).
RUN apt-get update \
 && apt-get install -y --no-install-recommends tesseract-ocr libglib2.0-0 libgl1 curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -m -d /home/app app \
 && mkdir -p /app/faces && chown -R app:app /app

COPY --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY --chown=app:app main.py ./

USER app

# Pre-download the EasyOCR English model so container startup does not
# depend on an internet fetch (main.py initializes the reader at import).
RUN python -c "import easyocr; easyocr.Reader(['en'], gpu=False)"

# DB settings are injected by docker-compose; registered face encodings
# live in /app/faces (mounted as a named volume in production).
ENV DB_HOST=mysql \
    DB_NAME=hr \
    DB_USER=root

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -fsS http://localhost:8082/ || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8082"]
