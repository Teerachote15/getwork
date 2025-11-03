# syntax=docker/dockerfile:1
# ใช้ Node.js base image (Alpine version)
FROM node:18-alpine

# ตั้ง working directory
WORKDIR /app

# คัดลอกไฟล์ package และ tsconfig เข้ามาเพื่อ cache การติดตั้ง dependencies
COPY package*.json tsconfig*.json ./

# ติดตั้ง dependencies
RUN npm install --no-audit --no-fund

# คัดลอก source code ที่เหลือเข้ามา
COPY . .

# เปิดพอร์ตที่ app รัน (ในที่นี้คือ 4000)
EXPOSE 4000

# กำหนด environment variables
ENV NODE_ENV=development
ENV PORT=4000

# รันคำสั่ง npm run dev ทันที (ไม่ต้องรอ wait-for-it.sh)
CMD ["npm", "run", "dev"]
