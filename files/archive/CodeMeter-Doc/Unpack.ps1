


<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param ()



function Invoke-DecryptCodeMeterPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param ()
    try{
        [void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

        $RootPath = (Resolve-Path -Path "$PSScriptRoot").Path
        $CipherArchivePath  = Join-Path $RootPath "CodeMeter-Doc.zip.aes"
        $ZipArchivePath  = Join-Path $RootPath "CodeMeter-Doc.zip"


        if([string]::IsNullOrEmpty("$ENV:AES_CRYPTER") -eq $False){
            $AesCryptConsoleExe = "$ENV:AES_CRYPTER"
        }else{
            $Cmd = get-command 'AesCryptConsole.exe'
            if($Null -eq $Cmd){ throw "AesCryptConsole.exe not found" }
            $AesCryptConsoleExe = $Cmd.Source
        }

        $passwd1 = Read-Host "Enter 1st password:"
        $phash   = Get-StringHash $passwd1
       
        Start-Process -FilePath "$AesCryptConsoleExe" -ArgumentList @("-d","$CipherArchivePath") -Wait *> "$ENV:Temp\out.log"
        if(-not(Test-Path -Path "$ZipArchivePath")) { throw "failed" }
        if([string]::IsNullOrEmpty("$ENV:DevelopmentRoot") -eq $True) { throw "DevelopmentRoot undefined!" }
        $OutPath = Join-Path "$ENV:DevelopmentRoot" "CodeMeterDoc"
        Remove-Item  -Path $OutPath -Force -Recurse -ErrorAction Ignore | Out-Null
        New-Item -Path $OutPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        Write-Host "Unpacking" -f Red
        try{
            Expand-7Zip -ArchiveFileName "$ZipArchivePath" -TargetPath "$OutPath" -Password "$phash"
        }catch{
            Write-Warning "$_"
        }
        $ExplorerCmd = get-command 'explorer.exe'
        if($Null -eq $ExplorerCmd){ throw "explorer.exe not found" }
        $ExplorerExe = $ExplorerCmd.Source
        &"$ExplorerExe" "$OutPath"
            
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}


Invoke-DecryptCodeMeterPackage