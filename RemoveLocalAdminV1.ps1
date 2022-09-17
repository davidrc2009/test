# Script to update User GPO from System context using a Schedule Task
# Written by Jörgen Nilsson
# ccmexec.com

$LocalAdminGroup = Get-LocalGroup -SID "S-1-5-32-544"
$Localadmingroupname = $LocalAdminGroup.name

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

# Get the UPN of the user that enrolled the computer to AAD
$AADInfo = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"
$Localadmins = Get-MembersOfGroup $Localadmingroupname

$guids = $AADInfo.GetSubKeyNames()
foreach ($guid in $guids) {
    $guidSubKey = $AADinfo.OpenSubKey($guid);
    $UPN = $guidSubKey.GetValue("UserEmail");
}

$Username = $UPN -split ("@")
$Username = $Username[0]

if ($UPN) {
    $Success = "Added LAP\$UPN as local administrator." | Out-File -FilePath $env:TEMP\LocalAdmin.log
    if (($Localadmins -contains $Username)) {
        Remove-LocalGroupMember -Group $Localadmingroupname -Member "LAP\$UPN"
     $Success = "Removido LAP\$UPN de grupo de administradores" | Out-File -FilePath C:\Windows\Temp\LocalAdminOK.log    }
    else {
        $Alreadymember = "LAP\$UPN no es un administrador local." | Out-File -FilePath $env:TEMP\LocalAdmin.log
    }
}
else {
    $Failed = "Failed to find an administrator candidate in registry." | Out-File -FilePath $env:TEMP\LocalAdmin.log
}
