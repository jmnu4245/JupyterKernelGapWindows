# --- CONFIGURACIÓN ---
$nombreTarea = "PruebaPostReinicio"
$nombreBat = "finalgap.bat"
$rutaBatPost = Join-Path -Path $PSScriptRoot -ChildPath $nombreBat
# Comprobar si WSL con Ubuntu ya está instalado
$ubuntuInstalled = wsl --list --online 2>$null | Select-String -Pattern "Ubuntu"
$ubuntuRegistered = wsl --list 2>$null | Select-String -Pattern "Ubuntu"

if (-not $ubuntuRegistered) {
    Write-Host "Ubuntu no está instalado. Instalando..."
    try {
        Unregister-ScheduledTask -TaskName $nombreTarea -Confirm:$false -ErrorAction SilentlyContinue
        
        # Crear acción: ejecutar el .bat
        $accion = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$rutaBatPost`""
        
        # Crear trigger: al inicio de sesión con retraso de 15 segundos
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $trigger.Delay = "PT15S"
        
        # Configuración: ejecutar con privilegios máximos
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        
        # Settings simples
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        # Registrar la tarea
        Register-ScheduledTask -TaskName $nombreTarea `
                               -Action $accion `
                               -Trigger $trigger `
                               -Principal $principal `
                               -Settings $settings `
                               -Force | Out-Null
        
        Write-Output "[OK] Tarea programada creada: $nombreTarea"
        
        # Configurar para que se ejecute solo una vez
        $xml = Export-ScheduledTask -TaskName $nombreTarea
        $xml = $xml -replace '<MultipleInstancesPolicy>.*</MultipleInstancesPolicy>', '<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>'
        Register-ScheduledTask -TaskName $nombreTarea -Xml $xml -Force | Out-Null
        Write-Output "[OK] Tarea programada configurada para ejecutarse solo una vez."
    # --- CREAR TAREA PROGRAMADA POST-REINICIO ---
    echo "[OK] Instalación de WSL iniciada. Se reiniciará el sistema en 10 segundos..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }catch {
        Write-Host "Error instalando WSL: $($_.Exception.Message)"
    }
}
else {
    Write-Host "Ubuntu ya está instalado. Pasamos la instalación de gap directamente"
    Start-Process "cmd.exe" "/c `"$rutaBatPost`"" -Wait
}