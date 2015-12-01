### Automated System Config ###

param($Step="A")

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
. (Join-Path $scriptpath ISEColorThemeCmdlets.ps1)
########## Variables #############

$localdrives = (gwmi win32_logicaldisk).deviceid
$installdir = (gci $localdrives -Filter "Install").FullName

If (!(test-path "$env:systemdrive\NMS\Logs\NMSlog.txt")) {
      New-Item -ItemType File "$env:systemdrive\NMS\Logs\NMSlog.txt" -force | Out-Null}
$system = $Env:Computername
$logfile = "$env:systemdrive\NMS\Logs\NMSlog.txt"

########## Functions #############

Function log ([string]$logdata)
  {
    $date = get-date -f G
    Write-Output  "$date - $system - $logdata" | Out-File $logfile -width 240 -Append
  }

Function Cleanup {
    $officeTempData = "C:\MSOCache\All Users" 
    $TempDirs = @("$env:LOCALAPPDATA\Temp","$env:USERPROFILE\Downloads","$env:windir\temp")
    [int64]$intsize = 0
    $TmpDirSize = GCI $TempDirs -Recurse -ea SilentlyContinue | % {$intsize+= $_.Length}
    $Total = $intsize | % {[math]::truncate($_ / 1MB)}
    If ($Total -gt 500) {
        Write-Host -fore green "Doing some house cleaning"
        $cleaning = gci $TempDirs -Recurse | % {Remove-Item $_ -Force}
        While ($cleaning) { write-host "." -nonew; sleep -Milliseconds 500 }
        Write-Host -fore yellow "Total temp directories removed: $($Total) (MB)"; sleep -Seconds 5
        } Else {Write-Host -fore green "Temp file cleanup: Temp directories size less than 500 MB. Skipping."}
    }

if (Should-Run-Step "A") {

#Disables UAC
$UACReg = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name "EnableLUA"
If ($UACReg.EnableLUA -ne 0) {
set-itemproperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name "EnableLUA" -value 0 -Force
log "UAC disabled"
Write-Host -fore Green "UAC Disabled."
}

$CurrentTZ = ([System.TimeZone]::CurrentTimeZone).StandardName
Write-Host -fore Yellow "Current time zone: $CurrentTZ"

#Set timezone if needed
$Tz = Read-Host "
Please select desired Time Zone


    1. CST
    2. Pacific
    3. Eastern
    4. US Mountain Standard Time
    5. Arizona
    0. Do not change
    
    "
    Switch ($Tz) {

    "1" {tzutil /s "Central Standard Time";Write-host -fore Green "Timezone set to CST"}
    "2" {tzutil /s "Pacific Standard Time";Write-host -fore Green "Timezone set to PST"}
    "3" {tzutil /s "Eastern Standard Time";Write-host -fore Green "Timezone set to EST"}
    "4" {tzutil /s "Mountain Standard Time";Write-host -fore Green "Timezone set to MST"}
    "5" {tzutil /s "US Mountain Standard Time";Write-host -fore Green "Timezone set to AZ time"}
    "0" {Write-Host -fore yellow "Time zone settings unchanged"}
    }


#Sets clock to NTP Pool settings
Write-Host -fore Green "Setting clock to NTP.org settings"; log "Setting clock to NTP.org settings"
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
Stop-Service w32time
Start-Service w32time

#Disable 'boot to start menu'
Write-Host -fore green "Checking for 'Disable boot to start' reg key.."

Push-Location

$RegDesktopKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
If (!(Get-ItemProperty $RegDesktopKey -name "OpenAtLogon" -ErrorAction SilentlyContinue))  {
    Set-Location $RegDesktopKey
    New-ItemProperty $RegDesktopKey -Name "OpenAtLogon" -Value 0 -PropertyType "Dword" -Force
    Write-Host -fore green "'OpenAtLogon' reg key created"; log "'OpenAtLogon' reg key created"
    } Else {
    Write-Host -fore green "'OpenAtLogon' reg key exists"; log "'OpenAtLogon' reg key exists"
    }

Pop-Location
#sleep -Seconds 2

#Disables AutoLogon if enabled
$AdminLogon = Get-Itemproperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon
If (($AdminLogon).AutoAdminLogon -ne 0) {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 0 
    Sleep -Seconds 1
    Write-Host -fore Green "Autologon registry entry disabled"; log "Autologon registry entry disabled"
    } Else {
    Write-Host -fore Green "Autologon already disabled"; Log "Autologon already disabled"
    }

#Change ISE theme to dark
#DOESNT WORK Get-ISETheme -File "$env:SystemDrive\NMS\Scripts\Visual Studio Code - Dark.StorableColorTheme.ps1xml" | Set-ISETheme

#Check OS version, Run .Net 3.5 install if Win8
### OS Version Reference ###  
# WinXp Pro SP3 = 5.1.2600
# Win7 Pro SP1 = 6.1.7601
# Win8.1 Pro = 6.3.9600
$Result = Dism /online /get-featureinfo /featurename:NetFx3
$OsVersion = (Get-WMIobject Win32_OperatingSystem).Version
    If ($OsVersion -like "5.1.*") {
        log "Windows XP Pro Detected"
        }Elseif ($OsVersion -like "6.1.*"){
        log "Windows 7 Pro Detected"
        }Elseif ($OsVersion -like "6.3.*") {
        Install-OSCNetFx3 -online
        }Else{
        log "$OSVer - Operating system not supported. Exiting setup." 
        $OSver = (Get-CimInstance Win32_OperatingSystem).Caption; Write-Host -fore red "$OSVer - Operating system not supported. Exiting setup."; Wait-For-Keypress; Exit
        }

#Enables remote desktop via registry
$RDPKey = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections
If ($RDPKey.fDenyTSConnections -ne 0) {
    Pushd
    Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0 -Type Dword -Force
    Popd
    log "Remote Desktop enabled"
    Write-Host -fore Green "Remote Desktop enabled"
    Sleep -Seconds 3
    } Else {
    Write-Host -fore Green "Remote Desktop already enabled"
    }

#install Office 2013 Pro Plus ################################## VALIDATED
$Logs = "$env:systemdrive\NMS\Logs"
$OfficeLogPath = "$logs\Office-install.txt"
$OfficePath = "$installdir\Office\Microsoft Office 2013 Pro Plus\Office_Professional_Plus_2013_64Bit_English\" # <----change \\VBOX path to $Installdir\Office

If (!(Test-Path $OfficeLogPath)) {New-Item -ItemType File $OfficeLogPath -Force | Out-Null}

$MSOffice = Test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90150000-0011-0000-1000-0000000FF1CE}"

 Switch ($MSOffice) { 
        "True" {log "Office 2013 Pro Plus already installed.";Should-Run-Step "B"}
        "False"{
            $Office13 = "$OfficePath\setup.exe"
            write-host -fore Green "Installing MS Office 2013 Pro Plus"
            $InstallOffice = Start-Process $Office13 -Wait
            While ($InstallOffice) {write-host -fore Green "." -nonew}
            If ($InstallOffice.ExitCode -gt 0) {
            Write-Warning "Office 2013 installation failed; Review Log file";log "Office 2013 installation failed"; Wait-For-Keypress
               } Else {
            Write-Host -fore Yellow "Restarting computer. Will resume script upon bootup...";log "Office 2013 installed. rebooting."; sleep -Seconds 3
            Restart-And-Resume $Script "B"
            }
        }
    }
} #End Step A

If (Should-run-step "B") {

$script = $myInvocation.MyCommand.Definition
$scriptPath = Split-Path -parent $script
. (Join-Path $scriptpath functions.ps1)
. (Join-Path $scriptpath New-MessageBox.ps1)

#install Ninite package
$NinitePkg = "$installdir\HomeApps.exe"
Start-Process $NinitePkg -Wait

#install Box
If (Test-Path "$installdir\BoxSyncSetup.exe") {
    Write-host -fore Green "Installing Box Sync"; Start-Process "$installdir\BoxSyncSetup.exe" -Wait
    } Else {
    Write-Warning "Box sync install file could not be located"}

#Install Brother printer (manual)
If (Test-path -Path "$Installdir\Printer drivers\HL-2270DW-inst-D1-win8-useu.EXE"){
    Write-host -fore green "Installing Brother printer"; log "Installing Brother print software"
    Start-process "$Installdir\HL-2270DW-inst-D1-win8-useu.EXE" -Wait
    } Else {
    Write-Warning "Could not find Brother printer software"; log "Brother printer drive download failed"
    }
$DLDir = "$env:systemdrive\NMS\Logs\pkgs"

#install Flux
$fluxURL = "https://justgetflux.com/dlwin.html"
Write-Host -fore Green "Downloading and installing Flux"
    Invoke-WebRequest $fluxURL -OutFile "$DLDir\Flux.exe"
    If (Test-Path "$DLDir\Flux.exe") {Start-Process "$DLDir\Flux.exe" -Wait}
        Else {Write-Warning "Flux download failed";Log "Flux install failed"}
#install VirtualBox (manual)
$VboxURL = "http://download.virtualbox.org/virtualbox/5.0.0/VirtualBox-5.0.0-101573-Win.exe"
$DLVbox = write-host -fore Green "Downloading and installing VirtualBox"
    Invoke-WebRequest $VboxURL -OutFile "$DLDir\Virtualbox.exe" 
If (Test-Path "$DLDir\Virtualbox.exe") {Start-Process "$DLDir\Virtualbox.exe" -Wait} 
    Else {Write-Warning "Virtualbox download failed"; log "Virtualbox install failed"}

#install Logitech MediaPlay mouse driver (manual)
$LogictechURL = "http://www.logitech.com/pub/techsupport/mouse/SetPoint6.67.82_64.exe"
write-host -fore Green "Downloading and installing Logitech mouse driver"; log "Downloading Logitech mouse driver" 
    Invoke-WebRequest $LogictechURL -OutFile "$DLDir\LogictechMPMousedrvr.exe"
If (Test-Path "$DLDir\LogictechMPMousedrvr.exe") {Start-Process "$DLDir\LogictechMPMousedrvr.exe" -Wait; kill -name LogictechMPMousedrvr -Confirm:$false}
    Else {Write-Warning "Logictech MediaPlay mouse driver download failed"; log "Logictech MediaPlay mouse driver download failed"}

#install Rainmeter
$RainURL = "https://github.com/rainmeter/rainmeter/releases/download/v3.2.1.2386/Rainmeter-3.2.1.exe"
write-host -fore Green "Downloading and installing Rainmeter"; log "Downloading Rainmeter" 
    Invoke-WebRequest $RainURL -OutFile "$DLDir\rainmeter.exe"
If (Test-Path "$DLDir\rainmeter.exe") {Start-Process "$DLDir\rainmeter" -Wait; Kill -name Rainmeter -Confirm:$false}
    Else {Write-Warning "Could not find Rainmeter install file"; log "Rainmeter install failed"}

Restart-And-Resume $script "C"

} #End Step B

 If(should-run-step "C") {

    
Write-host -fore Yellow "Is GDrive/Dropbox/Box installed and config'd??? Press any key to continue..." -BackgroundColor black; Wait-for-Keypress
$Drives = gwmi Win32_Logicaldisk | ? {$_.drivetype -eq "2" -or "3" -or "4"}
$gdrive = (gci $Drives.deviceID -Exclude | ? {$_.FullName -match "Google Drive"}).Fullname
$DesktopLink = "$gdrive\Google Drive\Desktop\$Env:Computername"
$boxpath = (gci $localdrives -Filter "Box Sync").FullName
$dropboxpath = (gci $localdrives -Filter "Dropbox").FullName

While (!(Test-Path $gdrive)) {Write-Warning "Google Drive isn't installed or configured. Try again."; Wait-for-Keypress}

$domain =  $env:USERDOMAIN
$user = $env:USERNAME
$SchedTask = Get-ScheduledTask
$global:pwd2 = $null

Function Get-Passwd {
        $SecurePW = Read-Host -AsSecureString "Please enter local password" #Get the password as a secure string
        $SecurePW2 = Read-Host -AsSecureString "Please re-enter local password"
        $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePW))
        $global:pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePW2))
        If ($pwd1.compareTo($global:pwd2) -eq 0) {
                Write-Host -fore Cyan "Local password set."; return
                    } Else {
                Write-Host -fore Red "Invalid credentials. Please check username/password and try again."; Get-Passwd
                }
        }
Get-Passwd

$Github = "$gdrive\GitHub"
If (Test-Path $Github) {Write-Host -fore Green "Github directory exists, creating Scheduled tasks";sleep -Seconds 3
    } else {
    While (!(Test-Path $Github)) {Write-Warning "Github repo not yet populated. Wait your fucking turn.";wait-for-keypress}
    }
#Cleanup Desktop task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDesktop") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn CleanDesktop /tr `
    "powershell.exe -Executionpolicy Bypass -file '$Github\System Maintenance\Clean-Desktop.ps1'"
    }
#Cleanup Downloads task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDownloads") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn CleanDownloads /tr `
    "powershell.exe -Executionpolicy Bypass -file '$Github\System Maintenance\Clean-Downloads.ps1'"
    }
#Zip Cam Uploads
If ($SchedTask.TaskName -notmatch "ZipCamUploads") {
schtasks /create /sc monthly /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn ZipCamUploads /tr `
    "powershell.exe -Executionpolicy Bypass -file '$Github\System Maintenance\Zip-Cam-Uploads.ps1'"
    }
#Warn-low-FreeSpace
If ($SchedTask.TaskName -notmatch "Warn-Low-FreeSpace") {
schtasks /create /sc hourly /mo 1 /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn Warn-Low-FreeSpace /tr `
    "powershell.exe -ExecutionPolicy bypass -file '$Github\Notifications\Warn-LowSpace.ps1'"
    }
#Change themes task
If ($SchedTask.TaskName -notmatch "Change Theme") {
schtasks /create /sc Monthly /st 08:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn "Change Theme" /tr `
    "powershell.exe -ExecutionPolicy bypass -file '$Github\wallpapers\Change-Theme.ps1'"
    }

#Create link to Desktop Dir in GDrive
$Drives = gwmi Win32_Logicaldisk | ? {$_.drivetype -eq "2" -or "3" -or "4"}
$gdrive = (gci $Drives.deviceID | ? {$_.FullName -match "Google Drive"}).Fullname

$targetfile = "$gdrive\Desktop\$Env:Computername"
If (Test-Path $targetfile) {md $targetfile -Force}
$sh = New-Object -ComObject WScript.Shell
$shortCut = $sh.CreateShortcut("$Env:USERPROFILE\Desktop\Desktop.lnk")
$shortCut.TargetPath = $targetfile
$shortCut.Save()


Cleanup
Write-Host -fore Cyan "Home PC setup complete. Will reboot now..."; Wait-for-Keypress
Clear-any-restart
Restart-Computer -Confirm:$false

} #End Step C, End Script