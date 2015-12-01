
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
 $box = 'C:\users\Preston\Google Drive\GitHub'
   
Get-Passwd


#### HANGS HERE ######


#Cleanup Desktop task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDesktop") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn CleanDesktop /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Clean-Desktop.ps1"
    }
#Cleanup Downloads task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDownloads") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn CleanDownloads /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Clean-Downloads.ps1"
    }
#Zip Cam Uploads
If ($SchedTask.TaskName -notmatch "ZipCamUploads") {
schtasks /create /sc monthly /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn ZipCamUploads /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Zip-Cam-Uploads.ps1"
    }
#Warn-low-FreeSpace
If ($SchedTask.TaskName -notmatch "Warn-Low-FreeSpace") {
schtasks /create /sc hourly /mo 1 /st 12:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn Warn-Low-FreeSpace /tr `
    "powershell.exe -ExecutionPolicy bypass -file $gdrive\Notifications\Warn-LowSpace.ps1"
    }
#Change themes task
If ($SchedTask.TaskName -notmatch "Change Theme") {
schtasks /create /sc Monthly /st 08:00 /RL highest /RU $domain\$user /RP $global:pwd2 /tn 'Change Theme' /tr `
    "powershell.exe -ExecutionPolicy bypass -file $box\wallpapers\Change-Theme.ps1"
    }
