@echo off
setlocal enabledelayedexpansion

:: IMPORTANTE: ¡¡¡DEBE EJECUTARSE COMO ADMINISTRADOR!!!
:: ==================================================================

echo.
echo ========================================
echo   INSTALADOR DE GAP + JUPYTER (WSL)
echo ========================================
echo.


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


:: --- CONFIRMACIÓN DE EJECUCIÓN POST-REINICIO ---
echo [POST-REINICIO] OK > "%TEMP%\wsl_post_reinicio_OK.txt"
echo %DATE% %TIME% >> "%TEMP%\wsl_post_reinicio_OK.txt"
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
    echo [INFO] Caracteristicas de Windows ya habilitadas. Continuando...
)
echo.
:: --- Instalar WSL y la distribución de Linux ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalarWsl.ps1"
pause
goto :eof
