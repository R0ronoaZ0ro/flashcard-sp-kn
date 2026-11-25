@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  echo No se encontro el lanzador py de Python.
  echo Instala Python 3.10 o superior y marca Add Python to PATH.
  pause
  exit /b 1
)
if not exist .venv py -3 -m venv .venv
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install pyinstaller
if errorlevel 1 (
  echo Fallo la instalacion de PyInstaller.
  pause
  exit /b 1
)
pyinstaller --noconfirm --clean --onefile --windowed --name FlashCardSPKNPanel app.py
if errorlevel 1 (
  echo Fallo la compilacion del EXE.
  pause
  exit /b 1
)
echo.
echo EXE creado en: dist\FlashCardSPKNPanel.exe
pause
