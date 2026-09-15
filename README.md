# SmartAir — Hệ Thống Giám Sát & Báo Cáo Chất Lượng Không Khí AIoT

SmartAir là giải pháp AIoT toàn diện theo dõi, cảnh báo và phân tích chất lượng không khí theo thời gian thực. Hệ thống thu thập dữ liệu từ cảm biến phần cứng (ESP32-S3), xử lý qua Backend Node.js và CSDL PostgreSQL, tích hợp mô hình học máy & LLM (Python FastAPI), hiển thị trên ứng dụng Flutter.

---

## 🛠️ Công Nghệ Sử Dụng (Tech Stack)

### 1. Phần cứng & Firmware (`/firmware`)
- **Vi điều khiển**: ESP32-S3 DevKit C1
- **Framework**: Arduino Framework (PlatformIO)
- **Cảm biến**: PMS5003 (Bụi mịn), BME280 (Nhiệt độ, Độ ẩm, Áp suất)
- **Thư viện**: `Adafruit BME280`, `PMS Library`, `ArduinoJson`

### 2. Máy chủ Backend (`/backend`)
- **Nền tảng**: Node.js & Express.js
- **Cơ sở dữ liệu**: PostgreSQL
- **Công cụ**: `node-cron`, Firebase Cloud Messaging (`firebase-admin`), `axios`

### 3. AI Engine (`/ai_engine`)
- **Nền tảng**: Python 3.x & FastAPI
- **Học máy**: `Scikit-learn` (Isolation Forest, Random Forest), `NumPy`, `psycopg2-binary`
- **LLM**: Claude API

### 4. Ứng dụng Di Động (`/mobile`)
- **Nền tảng**: Flutter (Dart)
- **Thư viện**: `provider`, `fl_chart`, `mobile_scanner`, `firebase_messaging`

---

## 📁 Cấu Trúc Dự Án

```text
SmartAir/
├── ai_engine/
├── backend/
├── firmware/
├── mobile/
├── DANH_SACH_CHUC_NANG.pdf
└── README.md
```

---

## 📋 Yêu Cầu Cài Đặt (Prerequisites)

- PostgreSQL (v14+)
- Node.js (v18+) & npm
- Python (v3.10+) & pip
- Flutter SDK (v3.19+)
- VS Code & Extension PlatformIO IDE

---

## 🚀 Hướng Dẫn Khởi Chạy Dự Án

### 1️⃣ Cơ sở dữ liệu (PostgreSQL)

```sql
CREATE DATABASE smartair;
```
```bash
psql -U postgres -d smartair -f backend/db/schema.sql
```

---

### 2️⃣ AI Engine (Python FastAPI) — Port 8000

```bash
cd ai_engine
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python main.py
```

---

### 3️⃣ Backend Service (Node.js) — Port 3000

```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

---

### 4️⃣ Mobile App (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

---

### 5️⃣ Firmware ESP32-S3

Mở thư mục `firmware` bằng VS Code (PlatformIO) và thực hiện nạp code:
```bash
pio run --target upload
```

