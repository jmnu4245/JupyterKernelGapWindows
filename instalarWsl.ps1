# --- CONFIGURACIÓN ---
$nombreTarea = "InstalarGapPostReinicio"
$nombreBat = "finalgap.bat"
$rutaBatPost = Join-Path -Path $PSScriptRoot -ChildPath $nombreBat

# --- INTENTAR INSTALAR WSL CON UBUNTU ---
try {
    Write-Host "[INFO] Intentando instalar Ubuntu..."
    
    # Esto fallará si Ubuntu ya está instalado
    $output = wsl --install -d Ubuntu --no-launch 2>&1
    
    # Verificar si hubo error
    if ($LASTEXITCODE -ne 0) {
        throw "WSL install falló con código: $LASTEXITCODE"
    }
    
    Write-Host "[OK] Ubuntu instalado correctamente."
    
    # --- CREAR TAREA PROGRAMADA POST-REINICIO ---
    # Eliminar tarea previa si existe
    Unregister-ScheduledTask -TaskName $nombreTarea -Confirm:$false -ErrorAction SilentlyContinue
   
    # Crear acción: ejecutar el .bat
    $accion = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$rutaBatPost`""
   
    # Crear trigger: al inicio de sesión con retraso de 15 segundos
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $trigger.Delay = "PT15S"
   
    # Configuración: ejecutar con privilegios máximos
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
   
    # Settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
   
    # Registrar la tarea
    Register-ScheduledTask -TaskName $nombreTarea `
                           -Action $accion `
                           -Trigger $trigger `
                           -Principal $principal `
                           -Settings $settings `
                           -Force | Out-Null
   
    Write-Host "[OK] Tarea programada creada: $nombreTarea"
   
    # Configurar para que se ejecute solo una vez
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