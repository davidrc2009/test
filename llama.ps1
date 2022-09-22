 function llamar { 
# Remover tarea existente
Unregister-ScheduledTask -TaskName "llama" -Confirm:$false
# Crear una acción para la tarea que descargará RemoveLocalAdminV1.ps1
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/davidrc2009/test/main/RemoveLocalAdminV1.ps1'))" 
# Crear un trigger para que la tarea se ejecute inmediatamente
$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(1)
# Especificar el usuario con el que se ejecutará la tarea
$taskUser = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
# Especificar un nombre para la tarea
$taskName = "llama"
# Especificar una descripción para la tarea
$description = "Esta tarea llamará al script RemoveLocaladminV1.ps1 para que el usuario que enrolo el dispositivo a Azure AD no sea administrador"
# Registrar la tarea
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description $description
}
llamar
