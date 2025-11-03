FROM python:3.10-slim

# Prevent Python from writing .pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies required for building some Python packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       gcc \
       git \
       curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt .

# Upgrade pip & install Python dependencies, including cryptography and pymysql
RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Install cryptography and pymysql directly if they are not in requirements.txt
RUN pip install cryptography pymysql

# Copy entire project
COPY . .

# Expose FastAPI port
EXPOSE 8000

# Default command in development mode (hot-reload)
CMD ["uvicorn", "model.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
