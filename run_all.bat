@echo off
title Bhasha Sangi - Classroom Fullstack Launcher
echo ===================================================
echo     BHASHA SANGI - MULTILINGUAL CLASSROOM SUITE
echo ===================================================
echo.
echo [1/2] Starting FastAPI Backend on http://127.0.0.1:8000 ...
start "BhashaSangi Backend (FastAPI + MySQL)" cmd /k "cd /d %~dp0backend && python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

echo [2/2] Starting Flutter Frontend on http://localhost:3000 ...
start "BhashaSangi Frontend (Flutter Web)" cmd /k "cd /d %~dp0frontend && flutter run -d edge --web-port 3000"

echo.
echo Both servers have been launched in separate windows!
echo Backend:  http://127.0.0.1:8000
echo Frontend: http://localhost:3000
echo.
pause
