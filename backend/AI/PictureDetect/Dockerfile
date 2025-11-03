# ใช้ base image ที่เบาและเหมาะกับ Python + TensorFlow
FROM python:3.10-slim

# ตั้ง working directory
WORKDIR /leoleonah/model

# คัดลอกไฟล์ทั้งหมด รวมถึง requirements.txt, model และโค้ด
COPY . .

# ติดตั้ง dependencies จาก requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# เปิดพอร์ตสำหรับ Flask
EXPOSE 5000

# รัน Flask app
CMD ["python", "api.py"]