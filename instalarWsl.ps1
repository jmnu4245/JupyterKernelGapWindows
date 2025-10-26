# --- CONFIGURACIÓN ---
$nombreTarea = "\instalacionkernelgap\InstalarGapPostReinicio"
$nombreBat = "finalgap.bat"
$rutaBatPost = Join-Path -Path $PSScriptRoot -ChildPath $nombreBat
# --- INTENTAR INSTALAR WSL CON UBUNTU ---
try {
    Write-Host "[INFO] Intentando instalar Ubuntu..."
    $output = wsl --install -d Ubuntu --no-launch 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL install falló con código: $LASTEXITCODE"
    }
    Write-Host "[OK] Ubuntu instalado correctamente."
    
    # --- CREAR TAREA PROGRAMADA POST-REINICIO ---
    Unregister-ScheduledTask -TaskName $nombreTarea -Confirm:$false -ErrorAction SilentlyContinue
    $accion = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$rutaBatPost`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $trigger.Delay = "PT15S"
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $nombreTarea `
                           -Action $accion `
                           -Trigger $trigger `
                           -Principal $principal `
                           -Settings $settings `
                           -Force | Out-Null
    Write-Host "[OK] Tarea programada creada: $nombreTarea"
    $xml = Export-ScheduledTask -TaskName $nombreTarea
    $xml = $xml -replace '<MultipleInstancesPolicy>.*</MultipleInstancesPolicy>', '<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>'
    Register-ScheduledTask -TaskName $nombreTarea -Xml $xml -Force | Out-Null
    Write-Host "[OK] Tarea programada configurada para ejecutarse solo una vez."
    Write-Host "[OK] Instalación de WSL iniciada. Se reiniciará el sistema en 10 segundos..."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} catch {
    # Ubuntu ya está instalado o hubo otro error
    Write-Host "[INFO] Ubuntu ya está instalado o hubo un error. Ejecutando instalación de GAP directamente..."
    
    # Ejecutar el bat directamente
    if (Test-Path $rutaBatPost) {
        Start-Process "cmd.exe" -ArgumentList "/c `"$rutaBatPost`"" -Wait -NoNewWindow
        Write-Host "[OK] Instalación de GAP completada."
    } else {
        Write-Host "[ERROR] No se encontró el archivo: $rutaBatPost" -ForegroundColor Red
        exit 1
    }
}