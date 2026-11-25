# shared_disk_wsl.ps1: mount D:\linux\shared_disk.vhdx into WSL at every logon.
# Run once from an *elevated* PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\shared_disk_wsl.ps1            # install
#   powershell -ExecutionPolicy Bypass -File .\shared_disk_wsl.ps1 -Uninstall # remove
param([switch]$Uninstall)

$Vhd      = 'D:\linux\shared_disk.vhdx'
$Name     = 'shared_disk'                   # appears in WSL as /mnt/wsl/shared_disk
$TaskName = 'WSL mount shared_disk'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
          ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Run this from an elevated (Administrator) PowerShell.' }

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    wsl --unmount "\\?\$Vhd" 2>$null
    Write-Host "Removed task '$TaskName'."
    return
}

if (-not (Test-Path $Vhd)) { throw "$Vhd not found." }

# Fast Startup / hibernation leave D: and the VHDX half-open, which is unsafe to
# open from Ubuntu afterwards. Turn them off.
powercfg /h off
Write-Host 'Hibernation and Fast Startup disabled.'

$action    = New-ScheduledTaskAction -Execute 'wsl.exe' -Argument "--mount --vhd $Vhd --name $Name"
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
               -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "Registered task '$TaskName'."

Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 5
wsl -e findmnt /mnt/wsl/$Name
Write-Host 'Next, inside WSL run:  bash shared_disk_wsl_links.sh   (creates ~/wslgit, ~/Latex shortcuts)'
