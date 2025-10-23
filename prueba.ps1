    # --- CONFIGURACIÓN ---
    $nombreTarea = "PruebaPostReinicio"
    $nombreBat = "prueba.bat"
    $rutaBatPostReinicio = Join-Path -Path $PSScriptRoot -ChildPath $nombreBat
    
    if (-not (Test-Path $rutaBatPostReinicio)) {
        Write-Error "[FALLO] No se encuentra el archivo: $rutaBatPostReinicio"
        exit 98
    }
    
    Write-Output "[OK] Script encontrado en: $rutaBatPostReinicio"

        Unregister-ScheduledTask -TaskName $nombreTarea -Confirm:$false -ErrorAction SilentlyContinue
        
        # Crear acción: ejecutar el .bat
        $accion = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$rutaBatPostReinicio`""
        
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
