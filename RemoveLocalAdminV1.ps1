$LocalAdminGroup = Get-LocalGroup -SID "S-1-5-32-544"
$Localadmingroupname = $LocalAdminGroup.name
$LocalUsersGroup = Get-LocalGroup -SID "S-1-5-32-545"
$Localusersgroupname = $LocalUsersGroup.name

# Función para obtener miembros de los grupos
function Get-MembersOfGroup {
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

# Función que crea una tarea programada para reiniciar Windows a una hora específica
function reiniciar { 
#remueve tarea si ya existe
Unregister-ScheduledTask -TaskName "reiniciar" -Confirm:$false
# Crea la acción
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'Restart-Computer -Force'
# Crea el disparador con la hora específica
$taskTrigger = New-ScheduledTaskTrigger -Once  -At 11:30am
# Se indica el usuario con el que se va ejecutar la tarea (LOCALSERVICE)
$taskUser = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
# El nombre de la tarea
$taskName = "reiniciar"
# Descripción de la tarea.
$description = "Fuerza el reinicio de la computadora"
# Registra la tarea programada
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description $description
}

# Obtine el UPN del usuario que enrolo el dispositivo a Azure AD
$AADInfo = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
$Localadmins = Get-MembersOfGroup $Localadmingroupname
$Localusers = Get-MembersOfUsersGroup $Localusersgroupname

$guids = $AADInfo.GetSubKeyNames()
foreach ($guid in $guids) {
    $guidSubKey = $AADinfo.OpenSubKey($guid);
    $UPN = $guidSubKey.GetValue("UserEmail");
}

$Username = $UPN -split ("@")
$Username = $Username[0]

# Condicionales
if ($UPN) {
    $Success = "Encontrado administrador LAP\$UPN." | Out-File -FilePath C:\Windows\Temp\LocalAdmin.log
    if (($Localadmins -contains $Username -AND $Localusers -NotContains $Username)) {
        Remove-LocalGroupMember -Group $Localadmingroupname -Member "LAP\$UPN"
		Add-LocalGroupMember -Group $Localusersgroupname -Member "LAP\$UPN"
        $Success = "Removido LAP\$UPN de grupo de administradores y añadido a usuarios" | Out-File -FilePath C:\Windows\Temp\LocalAdminOK.log
		reiniciar
     }
     	elseif (($Localadmins -contains $Username)) {
        Remove-LocalGroupMember -Group $Localadmingroupname -Member "LAP\$UPN"
        $Success = "Removido LAP\$UPN de grupo de administradores" | Out-File -FilePath C:\Windows\Temp\LocalAdminOK.log
		reiniciar
    }
    else {
        $Alreadymember = "LAP\$UPN no es un administrador local." | Out-File -FilePath C:\Windows\Temp\LocalAdmin.log
    }
}
else {
    $Failed = "No se encontró un administrador que cumpla las condiciones." | Out-File -FilePath C:\Windows\Temp\LocalAdmin.log
}
