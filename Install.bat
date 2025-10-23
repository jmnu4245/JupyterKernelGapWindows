@echo off
setlocal enabledelayedexpansion

:: IMPORTANTE: ¡¡¡DEBE EJECUTARSE COMO ADMINISTRADOR!!!
:: ==================================================================

echo.
echo ========================================
echo   INSTALADOR DE GAP + JUPYTER (WSL)
echo ========================================
echo.

echo Este script borrara la instalación actual de wsl e instalará una nueva, si ya esta wsl instalado debes ejecutar con permisos de sudo dentro del entorno: 
echo " wsl -u root bash -c 'cd ~/ && rm -rf setup-gap.sh && wget https://raw.githubusercontent.com/jmnu4245/JupyterKernelGapWindows/main/setup-gap.sh && bash ./setup-gap.sh' " 
echo Se realizara una instalación limpia de WSL y GAP + Jupyter.
echo.

timeout /t 4 >nul


:: --- PASO 0: Comprobar privilegios de Administrador ---
echo [INFO] Verificando privilegios de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script DEBE ejecutarse como Administrador.
    echo [ERROR] Clic derecho -^> Ejecutar como administrador.
    pause
    goto :eof
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
