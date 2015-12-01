#Remove all NMS settings/changes

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
    }

# ------------------------------------------- #
#                Script Imports               #
# ------------------------------------------- #
$script = $myInvocation.MyCommand.Definition
$scriptPath = Split-Path -parent $script
. (Join-Path $scriptpath functions.ps1)
. (Join-Path $scriptpath New-MessageBox.ps1)
. (Join-Path $scriptpath Install.NetFrameWork3.5.ps1)
###############################################


If (test-path 'c:\temp\NMS\NMSlog.txt') {
     Remove-Item 'c:\temp\NMS\NMSlog.txt' -force | Out-Null; write-host -fore Green "NMS log removed"
     }

$UACReg = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name "EnableLUA"

If ($UACReg.EnableLUA -ne 0) {
    set-itemproperty -Path "HKLM:\Software\Microsoft\Windows\Currentversion\policies\system" -Name "EnableLUA" -value 1 -Force
    }

If ($UACReg.EnableLUA -eq 1) {
    Write-Host -fore Green "UAC Enabled."
    } Else {
    Write-Host -fore Green "UAC disabled"
    }

$RegDesktopKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"

If (Get-ItemProperty $RegDesktopKey -Name "OpenAtLogon") {"Yep"} else {"nope"}

Push-Location

Set-Location $RegDesktopKey

Remove-ItemProperty $RegDesktopKey -Name "OpenAtLogon" -Force

Popd

