# Script to update User GPO from System context using a Schedule Task
# Written by JÃ¶rgen Nilsson
# ccmexec.com

$LocalAdminGroup = Get-LocalGroup -SID "S-1-5-32-544"
$LocalUsersGroup = Get-LocalGroup -SID "S-1-5-32-545"
$Localusersgroupname = $LocalUsersGroup.name
$Localadmingroupname = $LocalAdminGroup.name

function Get-MembersOfAdminGroup {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$GroupName,
        [string]$Computer = $env:COMPUTERNAME
    )

    $membersOfGroup = @()
    $ADSIComputer = [ADSI]("WinNT://$Computer,computer")
    $group = $ADSIComputer.psbase.children.find("$GroupName", 'Group')

    $group.psbase.invoke("members") | ForEach {
        $membersOfGroup += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
    }

    $membersOfGroup
}





function reiniciar { 
#remove old task
Unregister-ScheduledTask -TaskName "reiniciar" -Confirm:$false
# Create task action
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'Restart-Computer -Force'
# Create a trigger (Mondays at 4 AM)
$taskTrigger = New-ScheduledTaskTrigger -Once  -At 18:00pm
# The user to run the task
$taskUser = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
# The name of the scheduled task.
$taskName = "reiniciar"
# Describe the scheduled task.
$description = "Forcibly reboot the computer"
# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description $description
notificar3
}
function notificar { 
#remove old task
Unregister-ScheduledTask -TaskName "notificar" -Confirm:$false
#$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Users\David\Documents\notificarReinicio.ps1" # Specify what program to run and with its parameters
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/davidrc2009/test/main/notificarReinicio.ps1'))" # Specify what program to run and with its parameters

##$trigger = New-ScheduledTaskTrigger -Once -At 1:03am
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(7)
$task = Register-ScheduledTask -TaskName "notificar" -Trigger $trigger -Action $action
$task.Triggers.Repetition.Duration = "P1D" #Repeat for a duration of one day
$task.Triggers.Repetition.Interval = "PT5M" #Repeat every 30 minutes, use PT1H for every hour
$task | Set-ScheduledTask
 }


function notificar2 { 
#remove old task
Unregister-ScheduledTask -TaskName "notificar" -Confirm:$false
# Create task action
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/davidrc2009/test/main/notificarReinicio.ps1'))" # Specify what program to run and with its parameters

# Create a trigger 7 segundos
$taskTrigger = New-ScheduledTaskTrigger -Once  -At (Get-Date).AddSeconds(7)
# The user to run the task
$taskUser = New-ScheduledTaskPrincipal "$env:USERNAME"
# The name of the scheduled task.
$taskName = "notificar"
# Describe the scheduled task.
$description = "Notificar al usuario"
# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description $description
}



function notificar3{

Unregister-ScheduledTask -TaskName RebootMsg -Confirm:$false


$action    = New-ScheduledTaskAction -Execute "powershell.exe"  -Argument "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/davidrc2009/test/main/notificarReinicio.ps1'))" # Specify what program to run and with its parameters

$trigger   = New-ScheduledTaskTrigger -Once  -At (Get-Date).AddSeconds(7) -RepetitionDuration  (New-TimeSpan -Days 1)  -RepetitionInterval  (New-TimeSpan -Minutes 5)

# this should get the username of the current logged on user
# and schedule the task to run as that user
$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance �ClassName Win32_ComputerSystem | Select-Object -expand UserName)
$task      = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask RebootMsg -InputObject $task
##Start-ScheduledTask -TaskName RebootMsg

}






function Get-MembersOfUsersGroup {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$GroupName,
        [string]$Computer = $env:COMPUTERNAME
    )

    $membersOfGroup = @()
    $ADSIComputer = [ADSI]("WinNT://$Computer,computer")
    $group = $ADSIComputer.psbase.children.find("$GroupName", 'Group')

    $group.psbase.invoke("members") | ForEach {
        $membersOfGroup += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
    }

    $membersOfGroup
}




# Get the UPN of the user that enrolled the computer to AAD
$AADInfo = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
$Localadmins = Get-MembersOfAdminGroup $Localadmingroupname
$Localusers = Get-MembersOfUsersGroup $Localusersgroupname

$guids = $AADInfo.GetSubKeyNames()
foreach ($guid in $guids) {
    $guidSubKey = $AADinfo.OpenSubKey($guid);
    $UPN = $guidSubKey.GetValue("UserEmail");
}

$Username = $UPN -split ("@")
$Username = $Username[0]

if ($UPN) {
    $Success = "Added LAP\$UPN as local administrator." | Out-File -FilePath $env:TEMP\LocalAdmin.log
    if (($Localadmins -contains $Username -AND $Localusers -NotContains $Username)) {
        Remove-LocalGroupMember -Group $Localadmingroupname -Member "LAP\$UPN"
		Add-LocalGroupMember -Group $Localusersgroupname -Member "LAP\$UPN"
        $Success = "Removido LAP\$UPN de grupo de administradores y aÃ±adido a usuarios" | Out-File -FilePath C:\Windows\Temp\LocalAdminOK.log
		reiniciar
    }
	ElseIf (($Localadmins -contains $Username)) {
        Remove-LocalGroupMember -Group $Localadmingroupname -Member "LAP\$UPN"
        $Success = "Removido LAP\$UPN de grupo de administradores" | Out-File -FilePath C:\Windows\Temp\LocalAdminOK.log
		reiniciar
    }
    else {
        $Alreadymember = "LAP\$UPN no es un administrador local." | Out-File -FilePath C:\Windows\Temp\LocalAdminFail.log
    }
}
else {
    $Failed = "Failed to find an administrator candidate in registry." | Out-File -FilePath C:\Windows\Temp\LocalAdminFail.log
}