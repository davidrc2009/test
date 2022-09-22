 function llamar { 
#remove old task
Unregister-ScheduledTask -TaskName "llama2" -Confirm:$false
# Create task action
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/davidrc2009/test/main/RemoveLocalAdminV1.ps1'))" # Specify what program to run and with its parameters

# Create a trigger (Mondays at 4 AM)
$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(7)
# The user to run the task
$taskUser = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
# The name of the scheduled task.
$taskName = "llama2"
# Describe the scheduled task.
$description = "Test"
# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description $description
}
llamar