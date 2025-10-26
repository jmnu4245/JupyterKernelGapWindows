@echo off
setlocal

rem === Nombres de las tareas ===
set "nombreTarea1=\instalacionkernelgap\InstalarGapPostReinicio"
set "nombreTarea2=\instalacionkernelgap\InstaladorWSLPostReinicio"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script requiere privilegios de administrador.
    echo.
    echo Reintentando como administrador...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

echo Comprobando si existen las tareas programadas...

rem === Comprobar y eliminar tarea 1 ===
schtasks /query /tn "%nombreTarea1%" >nul 2>&1
if %errorlevel%==0 (
    echo Eliminando tarea "%nombreTarea1%"...
    schtasks /delete /tn "%nombreTarea1%" /f
) else (
    echo La tarea "%nombreTarea1%" no existe.
)

rem === Comprobar y eliminar tarea 2 ===
schtasks /query /tn "%nombreTarea2%" >nul 2>&1
if %errorlevel%==0 (
    echo Eliminando tarea "%nombreTarea2%"...
    schtasks /delete /tn "%nombreTarea2%" /f
) else (
    echo La tarea "%nombreTarea2%" no existe.
)

echo.
echo Proceso completado.
pause
endlocal
