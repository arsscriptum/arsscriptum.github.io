<#̷#̷\
#̷\ 
#̷\   ⼕ㄚ乃㠪尺⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   𝘗𝘰𝘸𝘦𝘳𝘴𝘩𝘦𝘭𝘭 𝘚𝘤𝘳𝘪𝘱𝘵 (𝘤) 𝘣𝘺 <𝘮𝘰𝘤.𝘥𝘶𝘰𝘭𝘤𝘪@𝘳𝘰𝘵𝘴𝘢𝘤𝘳𝘦𝘣𝘺𝘤>
#̷\
#̷\   ---> powershell -ep bypass -c ".\Build.ps1"
#̷\


<#
.SYNOPSIS
Build the

.DESCRIPTION
#>

[CmdletBinding()]
param()

#Requires -Version 4
Set-StrictMode -Version 'Latest'
#̷##>


$ErrorsCount = 0
$ScriptOutput = "#Requires -Version 2`n`n"

$CurrenPath = (Get-Location).Path
$IncludesPath = Join-Path $CurrenPath "inc"
$OutputPath = Join-Path $CurrenPath "out"
$Imports = Join-Path $IncludesPath "00_Imports.ps1"

$bdate = Get-Date -format "dd-MMM-yyyy HH:mm"
$FileContent = (Get-Content -Path $Imports)
$FileContent = $FileContent -replace "-!-BUILDDATE-!-", $bdate
Set-Content -Path $Imports -Value $FileContent
. $Imports

Import-Variables

$Scripts = (gci -Path $IncludesPath -Filter "*.ps1").Fullname

ForEach($s in $Scripts){
   Write-Host -f DarkRed "[pwsh] " -NoNewline
   Write-Host "importing $s" -f DarkYellow
   . "$s"
   # &"$Env:ComSpec" /c "$Script"
}  

$DateStr =  (Get-Date).GetDateTimeFormats()[19]
$Msg = "$ENV:COMPUTERNAME Has Started at $DateStr"
Send-EmailNotification -subject "On Start All" -msgbody "$Msg"


Set-Content "c:\Sysop\TestCompleted.txt" -Value "Ok"


