@echo off
title Launch Bhasha Sangi (Backend + Frontend)
echo ========================================================
echo   Launching Bhasha Sangi Full Stack System
echo   Backend: FastAPI (Aiven Cloud MySQL) on Port 8000
echo   Frontend: Flutter Web on Edge on Port 3000
echo ========================================================

echo 1. Starting FastAPI Backend on http://127.0.0.1:8000 ...
start "Bhasha Sangi Backend (FastAPI)" cmd /k "cd /d C:\Users\asus\Downloads\backend && python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

timeout /t 3 /nobreak > nul

echo 2. Starting Flutter Frontend on Microsoft Edge (Port 3000) ...
start "Bhasha Sangi Frontend (Edge)" cmd /k "cd /d C:\Users\asus\.gemini\antigravity\scratch\bhasha_sangi_frontend && flutter run -d edge --web-port 3000"

echo ========================================================
echo   Both services are launching in separate windows!
echo   Backend: http://127.0.0.1:8000
echo   Frontend: http://localhost:3000
echo ========================================================
pause
