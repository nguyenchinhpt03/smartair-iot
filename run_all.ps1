# SmartAir - One-Click Launcher PowerShell
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          SMARTAIR AIoT - KHOI DONG HE THONG" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiem tra .env
if (-not (Test-Path "$ROOT\backend\.env")) {
    Write-Host "[CANH BAO] Chua co backend\.env!" -ForegroundColor Red
}
if (-not (Test-Path "$ROOT\ai_engine\.env")) {
    Write-Host "[CANH BAO] Chua co ai_engine\.env!" -ForegroundColor Red
}

# 2. Chay AI Engine
Write-Host "[1/3] Khoi dong AI Engine (Port 8000)..." -ForegroundColor Green
$aiCmd = "cd '$ROOT\ai_engine'; if (Test-Path 'venv\Scripts\python.exe') { .\venv\Scripts\python.exe main.py } else { python main.py }"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $aiCmd

Start-Sleep -Seconds 3

# 3. Chay Backend
Write-Host "[2/3] Khoi dong Backend (Port 3000)..." -ForegroundColor Green
$backendCmd = "cd '$ROOT\backend'; npm run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd

Start-Sleep -Seconds 3

# 4. Chay Mobile
Write-Host "[3/3] Khoi dong Mobile App Flutter..." -ForegroundColor Green
$mobileCmd = "cd '$ROOT\mobile'; flutter run -d android"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $mobileCmd

Write-Host ""
Write-Host "Da khoi chay ca 3 dich vu tren cac cua so rieng biet!" -ForegroundColor Cyan
