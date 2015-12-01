#Create Tasks
If ($env:COMPUTERNAME -match "villapr") {
    $gdrive = "C:\Users\Villavpr\Google Drive\Github"
    }Else{
    $gdrive = "G:\Google Drive\GitHub"
    }
if (!(Test-Path $gdrive)){Write-Warning "Google Drive not installed or configured"; sleep -seconds 4;exit 1}

$domain =  $env:USERDOMAIN
$PASS = READ-HOST "Enter password" -AsSecureString
$user = $env:USERNAME
$SchedTask = Get-ScheduledTask


#Cleanup Desktop task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDesktop") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $PASS /tn CleanDesktop /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Clean-Desktop.ps1"
    }
#Cleanup Downloads task - Runs daily @ noon
If ($SchedTask.TaskName -notmatch "CleanDownloads") {
schtasks /create /sc daily /st 12:00 /RL highest /RU $domain\$user /RP $PASS /tn CleanDownloads /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Clean-Downloads.ps1"
    }
#Zip Cam Uploads
If ($SchedTask.TaskName -notmatch "ZipCamUploads") {
schtasks /create /sc monthly /st 12:00 /RL highest /RU $domain\$user /RP $PASS /tn ZipCamUploads /tr `
    "powershell.exe -Executionpolicy Bypass -file $gdrive\System Maintenance\Zip-Cam-Uploads.ps1"
    }
#Warn-low-FreeSpace
If ($SchedTask.TaskName -notmatch "Warn-Low-FreeSpace") {
schtasks /create /sc hourly /mo 1 /st 12:00 /RL highest /RU $domain\$user /RP $PASS /tn Warn-Low-FreeSpace /tr `
    "powershell.exe -ExecutionPolicy bypass -file $gdrive\Notifications\Warn-LowSpace.ps1"
    }
#Change themes task
If ($SchedTask.TaskName -notmatch "Change Theme") {
schtasks /create /sc Monthly /st 8:00 /RL highest /RU $domain\$user /RP $PASS /tn Change Theme /tr `
    "powershell.exe -ExecutionPolicy bypass -file $gdrive\wallpapers\Change-Theme.ps1"
    }