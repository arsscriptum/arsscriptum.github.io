


<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param ()



function Invoke-DecryptDejaPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    try{
        [void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

        $RootPath = (Resolve-Path -Path "$PSScriptRoot").Path
        $CipherArchivePath  = Join-Path $RootPath "DejaInsight.SDK.zip.aes"
        $ZipArchivePath  = Join-Path $RootPath "DejaInsight.SDK.zip"
        $7zCmd = get-command '7z.exe'
        if($Null -eq $7zCmd){ throw "7z.exe not found" }
        $7zCmdExe = $7zCmd.Source

        $mod = Import-Module "7Zip4Powershell" -Force -PassThru
        if($Null -eq $mod){ throw "7Zip4Powershell not found" }


        $Cmd = get-command 'AesCryptConsole.exe'
        if($Null -eq $Cmd){ throw "AesCryptConsole.exe not found" }
        $AesCryptConsoleExe = $Cmd.Source

        $passwd1 = Read-Host "Enter 1st password:"
        $phash   = Get-StringHash $passwd1
       
        Start-Process -FilePath "$AesCryptConsoleExe" -ArgumentList @("-d","$CipherArchivePath") -Wait *> "$ENV:Temp\out.log"
        if(-not(Test-Path -Path "$ZipArchivePath")) { throw "failed" }
        if([string]::IsNullOrEmpty("$ENV:DevelopmentRoot") -eq $True) { throw "DevelopmentRoot undefined!" }
        $OutPath = Join-Path "$ENV:DevelopmentRoot" "DejaInsight"
        Remove-Item  -Path $OutPath -Force -Recurse -ErrorAction Ignore | Out-Null
        New-Item -Path $OutPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        Write-Host "Unpacking" -f Red
        Expand-7Zip -ArchiveFileName "$ZipArchivePath" -TargetPath "$OutPath" -Password "$phash"
        $ExplorerCmd = get-command 'explorer.exe'
        if($Null -eq $ExplorerCmd){ throw "explorer.exe not found" }
        $ExplorerExe = $ExplorerCmd.Source
        &"$ExplorerExe" "$OutPath"
            
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}


Invoke-DecryptDejaPackage