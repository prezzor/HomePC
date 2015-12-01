if not exist (c:\NMS\scripts) md c:\NMS\scripts
pushd %~dp0
xcopy *.* c:\NMS\scripts /s /i

rem powershell.exe $shell = New-Object -ComObject Wscript.Shell; Set-ExecutionPolicy Unrestricted | echo $shell.sendkeys("Y`r`n")
powershell.exe -executionpolicy bypass -file "C:\NMS\scripts\Home-NMS.ps1" -noexit