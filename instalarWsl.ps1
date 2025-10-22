$batPath = Join-Path -Path $PSScriptRoot -ChildPath  "finalgap.bat"

# Comprobar si WSL con Ubuntu ya está instalado
$ubuntuInstalled = wsl --list --online 2>$null | Select-String -Pattern "Ubuntu"
$ubuntuRegistered = wsl --list 2>$null | Select-String -Pattern "Ubuntu"

if (-not $ubuntuRegistered) {
    Write-Host "Ubuntu no está instalado. Instalando..."
    try {
        wsl --install -d Ubuntu
        Write-Host "Instalación iniciada correctamente."

        # Crear tarea programada para ejecutar el BAT
        $taskName = "Ejecutar_BAT_Post_WSL"
        $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batPath`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Ejecuta el BAT tras instalar WSL"
        
        Write-Host "Tarea programada creada correctamente."

        echo "[OK] Instalación de WSL iniciada. Se reiniciará el sistema en 10 segundos..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    catch {
        Write-Host "Error instalando WSL: $($_.Exception.Message)"
    }
}
else {
    Write-Host "Ubuntu ya está instalado. Pasamos la instalación de gap directamente"
    Start-Process "cmd.exe" "/c `"$batPath`""
}
