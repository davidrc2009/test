Add-Type -AssemblyName System.Windows.Forms
$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
$balmsg.BalloonTipText = 'Se ha programado un reinicio en su ordenador a las 13:00, por favor guarde su información'
$balmsg.BalloonTipTitle = "Atención $Env:USERNAME"
$balmsg.Visible = $true
$balmsg.ShowBalloonTip(20000)