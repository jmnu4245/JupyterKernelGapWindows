@echo off
setlocal
:: IMPORTANTE: ¡¡¡DEBE EJECUTARSE COMO ADMINISTRADOR!!!
:: ==================================================================
:: --- PASO 0: Comprobar privilegios de Administrador ---
echo [INFO] Verificando privilegios de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script DEBE ejecutarse como Administrador.
    echo [ERROR] Clic derecho -> Ejecutar como administrador.
    pause
    goto :eof
)
echo [INFO] Privilegios de administrador confirmados.
echo.

set "REPO_URL=https://raw.githubusercontent.com/jmanu/tu-repo/JupyterKernelGapWindows/setup-gap.sh"

:: Comando base que se ejecutara dentro de bash
set "BASH_CMD=wget %REPO_URL% -O /tmp/setup-gap.sh && chmod +x /tmp/setup-gap.sh && /tmp/setup-gap.sh"

:: Comando instalar wsl
set "DIRECT_RUN_CMD=powershell.exe -Command "wsl.exe -u root -- bash -c '%BASH_CMD%'"

:: Comando iniciar script en wsl
set "RUNONCE_CMD=powershell.exe -WindowStyle Hidden -Command "wsl.exe -u root -- bash -c '%BASH_CMD%'"

echo [INFO] Verificando si Ubuntu (WSL) ya esta instalado...
wsl -l | findstr /C:"Ubuntu" >nul 2>&1

if %errorlevel% equ 0 (
    echo [INFO] Ubuntu ya esta instalado.
    goto :RunSetup
) else (
    echo [INFO] Ubuntu no encontrado.
    goto :InstallWSL
)

:: ------------------------------------------------------------------
:InstallWSL
:: Seccion para instalar WSL por primera vez
:: ------------------------------------------------------------------
echo [INFO] Iniciando la instalacion de WSL y Ubuntu...
wsl --install -d Ubuntu

if %errorlevel% neq 0 (
    echo [ERROR] La instalacion de WSL fallo.
    echo [ERROR] El comando que fallo fue:
    echo wsl --install -d Ubuntu
    echo [ERROR] Asegurate de que la virtualizacion (VT-x/AMD-V) esta activada en la BIOS.
    pause
    goto :eof
)

echo [INFO] WSL instalado. El sistema DEBE reiniciarse.
echo [INFO] Configurando el script de instalacion para el proximo inicio...

REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetupGAP" /t REG_SZ /d "%RUNONCE_CMD%" /f

if %errorlevel% neq 0 (
    echo [ERROR] No se pudo crear la tarea de RunOnce en el Registro.
    echo [ERROR] El comando que fallo fue:
    echo REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "SetupGAP" /t REG_SZ /d "%RUNONCE_CMD%" /f
    pause
    goto :eof
)

echo [INFO] Tarea post-reinicio creada.
echo [INFO] El ordenador se reiniciara en 10 segundos...
shutdown /r /t 10
goto :eof

:: ------------------------------------------------------------------
:RunSetup
:: Seccion para ejecutar el script si WSL ya estaba instalado
:: ------------------------------------------------------------------
echo [INFO] Ejecutando el script de configuracion de GAP directamente...
echo [INFO] Se abrira una ventana de WSL. Por favor, espera a que termine.

:: Ejecutamos el comando
%DIRECT_RUN_CMD%

if %errorlevel% neq 0 (
    echo [ERROR] El script de configuracion fallo.
    echo [ERROR] El comando que fallo fue:
    echo %DIRECT_RUN_CMD%
    pause
    goto :eof
)

echo.
echo [INFO] ¡Script de configuracion completado con exito!
echo [INFO] Puedes cerrar esta ventana.
pause
goto :eof
