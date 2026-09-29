@echo off
title Bhasha Sangi FastAPI Backend
cd /d "%~dp0"
echo ========================================================
echo Starting Bhasha Sangi FastAPI Backend on http://127.0.0.1:8000
echo ========================================================
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
pause
