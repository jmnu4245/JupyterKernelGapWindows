@echo off
setlocal enabledelayedexpansion

:: IMPORTANTE: ¡¡¡DEBE EJECUTARSE COMO ADMINISTRADOR!!!
:: ==================================================================

echo.
echo ========================================
echo   INSTALADOR DE GAP + JUPYTER (WSL)
echo ========================================
echo.

echo Si ya esta wsl instalado se recomienda parar este sript y ejecutar finalgap.bat
echo.
echo La instalacion llevara a cabo varios reinicios, espere pacientemente y siga las instrucciones.
echo.
echo Si desea continuar con la instalacion de WSL y GAP + Jupyter, espere: 
echo " wsl -u root bash -c 'cd ~/ && rm -rf setup-gap.sh && wget https://raw.githubusercontent.com/jmnu4245/JupyterKernelGapWindows/main/setup-gap.sh && bash ./setup-gap.sh' " 
echo.

timeout /t 8 >nul


echo [INFO] Verificando privilegios de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script requiere privilegios de administrador.
    echo.
    echo Reintentando como administrador...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

echo [INFO] Privilegios de administrador confirmados.
echo.


:: Obtener la ruta completa de este script
set "SCRIPT_PATH=%~f0"

:: --- Verificar y habilitar características de Windows ---
echo [INFO] Verificando caracteristicas de Windows necesarias...
powershell -ExecutionPolicy Bypass -File "%~dp0activarCaracteristicas.ps1"
if %errorlevel% equ 1 (
    echo.
    echo [INFO] Reiniciando el sistema...
    shutdown /r /t 10 /c "Reiniciando para completar la instalacion de WSL"
    pause
    goto :eof
) else (
    REM Eliminar tareas programadas si existen
   
    echo [INFO] Caracteristicas de Windows ya habilitadas. Continuando...
)
echo.
schtasks /Delete /TN "InstaladorWSL_PostReinicio" /F >nul 2>&1
:: --- Instalar WSL y la distribución de Linux ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalarWsl.ps1"
pause
goto :eof
