@echo off
chcp 65001 >nul
title SmartAir - One-Click Launcher

echo ==========================================================
echo           SMARTAIR AIoT - KHOI DONG HE THONG
echo ==========================================================
echo.

set ROOT=%~dp0

:: 1. Kiem tra file .env
if not exist "%ROOT%backend\.env" (
    echo [CANH BAO] Chua co backend\.env!
)
if not exist "%ROOT%ai_engine\.env" (
    echo [CANH BAO] Chua co ai_engine\.env!
)

:: 2. Khoi dong AI Engine (Port 8000)
echo [1/3] Dang khoi dong AI Engine (Port 8000)...
start "SmartAir - AI Engine (Port 8000)" cmd /k "cd /d %ROOT%ai_engine && venv\Scripts\python.exe main.py"

:: Cho 3 giay de AI Engine chay truoc
timeout /t 3 /nobreak >nul

:: 3. Khoi dong Backend (Port 3000)
echo [2/3] Dang khoi dong Backend Node.js (Port 3000)...
start "SmartAir - Backend (Port 3000)" cmd /k "cd /d %ROOT%backend && npm run dev"

:: Cho 3 giay
timeout /t 3 /nobreak >nul

:: 4. Khoi dong Mobile Flutter
echo [3/3] Dang khoi dong Mobile App Flutter...
start "SmartAir - Flutter Mobile" cmd /k "cd /d %ROOT%mobile && flutter run -d android"

echo.
echo ==========================================================
echo   DA KHOI DONG XONG CA 3 DICH VU TREN 3 CUA SO CMD!
echo   - AI Engine: http://localhost:8000/health
echo   - Backend:   http://localhost:3000/health
echo   - Mobile:    Dang khoi chay Flutter
echo ==========================================================
echo.
pause
