# 0. Inicializar la variable de reinicio
$nombreTarea = "\instalacionkernelgap\InstaladorWSLPostReinicio"
$nombreBat = "install.bat"
$rutaBatPostReinicio = Join-Path -Path $PSScriptRoot -ChildPath $nombreBat
$globalRestartNeeded = $false
# 1. Obtener el estado de las características
$wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
$vm = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
# 2. Comprobar y habilitar WSL
if ($wsl.State -ne 'Enabled') {
    Write-Output '[INFO] Habilitando Subsistema de Windows para Linux...'
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $globalRestartNeeded = $true 
} else {
    Write-Output '[OK] Subsistema de Windows para Linux ya habilitado.'
}
# 3. Comprobar y habilitar VirtualMachinePlatform
if ($vm.State -ne 'Enabled') {
    Write-Output '[INFO] Habilitando Virtual Machine Platform...'
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $globalRestartNeeded = $true 
} else {
    Write-Output '[OK] Virtual Machine Platform ya habilitada.'
}
# 4. Reinicio y progamación post-reinicio
if ($globalRestartNeeded) {
    Write-Output '[INFO] La instalación ha finalizado y se requiere un reinicio.'
    # --- CONFIGURACIÓN ---
    if (-not (Test-Path $rutaBatPostReinicio)) {
        Write-Error "[FALLO] No se encuentra el archivo: $rutaBatPostReinicio"
        exit 98
    }
    
    Write-Output "[OK] Script encontrado en: $rutaBatPostReinicio"
    
    # --- CREAR TAREA PROGRAMADA ---
    
    Write-Output "[INFO] Creando tarea programada..."
    try {
        # Eliminar tarea si ya existe
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
        
    } catch {
        Write-Error "[FALLO] No se pudo crear la tarea programada: $_"
        exit 99
    }
    # --- INFORMACIÓN PARA EL USUARIO ---
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "  INFORMACION DE REINICIO"
    Write-Output "=========================================="
    Write-Output "[!!!] El sistema se reiniciara en 15 segundos"
    Write-Output "[INFO] Tras el reinicio e inicio de sesión,"
    Write-Output "[INFO] la instalación continuara automáticamente."
    Write-Output "=========================================="
    Write-Output ""
    Start-Sleep -Seconds 15
    Restart-Computer -Force
    exit 1
} else {
    Write-Output '[OK] Todas las caracteristicas necesarias ya estaban habilitadas. No se necesita reinicio.'
    exit 0
}