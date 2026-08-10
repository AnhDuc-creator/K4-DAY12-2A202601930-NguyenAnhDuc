# ---- Stage 1: Builder — cài dependency, không đi vào image cuối ----
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Stage 2: Runtime — chỉ mang theo thư viện đã cài và source code ----
FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app/ app/
COPY utils/ utils/

# Chạy bằng user thường: thoát được khỏi app cũng không thành root trên host
RUN useradd --create-home appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Image slim không có curl, nên dùng Python; đọc PORT động vì cloud tự gán cổng
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.getenv('PORT', '8000') + '/healthz', timeout=3)"

# Shell form để biến $PORT được expand lúc chạy
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]