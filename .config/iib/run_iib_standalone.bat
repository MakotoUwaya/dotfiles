@echo off
title Infinite Image Browsing (Standalone)

cd /d "%~dp0"
set "PYTHON=%~dp0venv\Scripts\python.exe"
set "IIB_DIR=%~dp0extensions\sd-webui-infinite-image-browsing"
set "SM_IMAGES=F:\Stable_Diffusion\StabilityMatrix\Images"
set "COMFY_OUTPUT=F:\Stable_Diffusion\StabilityMatrix\Packages\ComfyUI\output"
set "FORGE_OUTPUT=%~dp0output"

echo ========================================================
echo  Infinite Image Browsing (Standalone)
echo ========================================================
echo Running lightweight image browser server (No GPU/VRAM used).
echo.
echo URL: http://127.0.0.1:8000
echo Press Ctrl+C or close this window to stop.
echo ========================================================
echo.

cd /d "%IIB_DIR%"
"%PYTHON%" app.py --port 8000 --extra_paths "%SM_IMAGES%" "%COMFY_OUTPUT%" "%FORGE_OUTPUT%"

pause
