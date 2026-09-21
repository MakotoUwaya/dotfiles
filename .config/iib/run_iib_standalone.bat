@echo off
title Infinite Image Browsing (Standalone)

cd /d "%~dp0"
set "FORGE_DIR=%~dp0"
if "%FORGE_DIR:~-1%"=="\" set "FORGE_DIR=%FORGE_DIR:~0,-1%"

set "PYTHON=%FORGE_DIR%\venv\Scripts\python.exe"
set "IIB_DIR=%FORGE_DIR%\extensions\sd-webui-infinite-image-browsing"
set "SM_IMAGES=F:\Stable_Diffusion\StabilityMatrix\Images"
set "COMFY_OUTPUT=F:\Stable_Diffusion\StabilityMatrix\Packages\ComfyUI\output"

echo ========================================================
echo  Infinite Image Browsing (Standalone)
echo ========================================================
echo Running lightweight image browser server (No GPU/VRAM used).
echo Sharing database, cache, and settings with WebUI Forge Neo.
echo.
echo URL: http://127.0.0.1:8000
echo Press Ctrl+C or close this window to stop.
echo ========================================================
echo.

cd /d "%IIB_DIR%"
"%PYTHON%" app.py --port 8000 --sd_webui_dir "%FORGE_DIR%" --extra_paths "%SM_IMAGES%" "%COMFY_OUTPUT%"

pause
