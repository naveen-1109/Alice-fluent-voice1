@echo off
echo =========================================
echo  FluentVoice AI Backend v2.0 Setup
echo =========================================

:: Navigate to the backend folder (where this .bat file lives)
cd /d "%~dp0"
echo Working directory: %CD%

:: Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Install from https://python.org
    pause
    exit /b
)

:: Create virtual environment inside backend folder
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

:: Activate
call venv\Scripts\activate.bat

:: Install base dependencies
echo Installing dependencies (this may take a few minutes)...
pip install -r requirements.txt

:: Install ffmpeg-python for Whisper audio conversion
pip install ffmpeg-python

:: Whisper model will auto-download (~150MB) on first request
echo.
echo =========================================
echo  Starting FluentVoice AI API on port 8000
echo  Swagger docs: http://localhost:8000/docs
echo  NOTE: Whisper 'base' model (~150MB) will
echo        download automatically on first use.
echo =========================================
python main.py
pause
