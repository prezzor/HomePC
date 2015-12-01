Function New-Messagebox {
 
<#
.Synopsis
Display a VisualBasic style message box.
.Description
This function will display a graphical messagebox, like the one from VisualBasic
and VBScript. You must specify a message. The default button is OKOnly and the 
default icon is for Information. If you want to use the value from a button click
in a PowerShell expression, use the -Passthru parameter.
 
The message box will remain displayed until the user clicks a button. The box may 
also not appear on top, but if you have audio enabled you should hear the Windows 
exclamation sound.
.Parameter Message
The text to display. Keep it short.
.Parameter Button
The button set to display. The default is OKOnly. Possible values are:
    OkOnly
    OkCancel
    AbortRetryIgnore
    YesNoCancel
    YesNo
    RetryCancel
.Parameter Icon
The icon to display. The default is Information. Possible values are:
    Critical
    Question
    Exclamation
    Information
.Parameter Title
The message box title. The default is no title. The title should be less than 
24 characters long, otherwise it will be truncated.
.Parameter NoPassthru
Use this parameter if you DO NOT want the button value to be passed to the pipeline.
.Example
PS C:\> New-Messagebox "Time to go home!"
Display a message box with no title and the OK button.
.Example
PS C:\> $rc=New-Messagebox -message "Do you know what you're doing?" -icon exclamation -button "YesNoCancel" -title "Hey $env:username!!" 
Switch ($rc) {
 "Yes" {"I hope your resume is up to date."}
 "No" {"Wise move."}
 "Cancel" {"When in doubt, punt."}
 Default {"nothing returned"}
}
.Example
PS C:\> New-MessageBox -message "Are you the walrus?" -icon question -title "Hey, Jude" -button YesNo
.Inputs
None
.Outputs
[system.string]
#>
 
[cmdletbinding()]
 
Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage = "Specify a display message")]
[ValidateNotNullorEmpty()]
[string]$Message,
[ValidateSet("OkOnly","OkCancel","AbortRetryIgnore","YesNoCancel","YesNo","RetryCancel")]
[string]$Button="OkOnly",
[ValidateSet("Critical", "Question", "Exclamation", "Information")]
[string]$Icon="Information",
[string]$Title,
[switch]$NoPassthru
)
 
#load the necessary assembly
Try { 
    Add-Type -AssemblyName "Microsoft.VisualBasic" -ErrorAction Stop     
    #create the message box using the parameter values
    $returnValue = [microsoft.visualbasic.interaction]::Msgbox($message,"$button,$icon",$title)
}
Catch {
    Write-Warning "Failed to add Microsoft.VisualBasic assembly or create the messagebox."
    Write-Warning $error[0].Exception.Message
}
#do not write return value if -NoPassthru is called
if (-Not $NoPassthru) {
    Write-Output $returnValue
} 
} #end function