
$CurrentPath = (Get-Location).Path
$CmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine   
[string[]]$UserCommandArray = $CmdLine.Split(' ')
$ProgramFullPath = $UserCommandArray[0].Replace('"','')
$ProgramDirectory = (gi $ProgramFullPath).DirectoryName
$ProgramName = (gi $ProgramFullPath).Name
$ProgramBasename = (gi $ProgramFullPath).BaseName

if(($CmdLine -match 'pwsh.exe') -Or ($CmdLine -match 'powershell.exe')){
    $MODE_NATIVE = $False
    $MODE_SCRIPT = $True
}else{
    $MODE_NATIVE = $True
    $MODE_SCRIPT = $False
}



cls

if($MODE_NATIVE -eq $True) { Write-Host "$ProgramFullPath" -f Green}

Write-Host "=====================================" -f Red
Write-Host "=====================================" -f Yellow
0..15 | % {
    Write-Host "$_ " -n -f Red 
    Start-Sleep 1
}

Write-Host "`n=====================================" -f Blue
Write-Host "=====================================" -f Magenta