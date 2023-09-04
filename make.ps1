
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)] 
    [Alias('r')]
    [string]$TestPath = "$PSScriptRoot\_site",
    [Parameter(Mandatory = $false)] 
    [Alias('c')]
    [switch]$Clean,
    [Parameter(Mandatory = $false)] 
    [Alias('m')]
    [switch]$Merge,
    [Parameter(Mandatory = $false)] 
    [switch]$ReverseMerge,    
    [Parameter(Mandatory = $false)] 
    [Alias('p')]
    [switch]$Push,
    [Parameter(Mandatory = $false)] 
    [Alias('i','v')]
    [switch]$Version
)
    $RemoteBranch  = 'live'
    $CurrentBranch = git branch --show-current
    if($CurrentBranch -eq 'live'){
        $RemoteBranch  = 'test'
    }

    function Get-Script([string]$prop){
        $ThisFile = $script:MyInvocation.MyCommand.Path
        return ((Get-Item $ThisFile)|select $prop).$prop
    }

    $MakeScriptPath = split-path $script:MyInvocation.MyCommand.Path
    $ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).FullName
    $ScriptsPath = Join-Path $MakeScriptPath 'scripts'
    $SiteVersionScriptPath = Join-Path $ScriptsPath 'SiteVersion.ps1'
    $WriteConsoleScriptPath = Join-Path $ScriptsPath 'WriteConsoleExtended.ps1'
    . "$SiteVersionScriptPath"
    . "$WriteConsoleScriptPath"

    #===============================================================================
    # Root Path
    #===============================================================================
    $Global:ConsoleOutEnabled              = $true
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:CurrPath                       = $MakeScriptPath
    $Script:RootPath                       = (Get-Location).Path
    If( $PSBoundParameters.ContainsKey('Path') -eq $True ){
        $Script:RootPath = $Path
    }
    If( $PSBoundParameters.ContainsKey('ModuleIdentifier') -eq $True ){
        $Global:ModuleIdentifier = $ModuleIdentifier
    }else{
        $Global:ModuleIdentifier = (Get-Item $Script:RootPath).Name
    }

    #===============================================================================
    # Script Variables
    #===============================================================================
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:Time                           = Get-Date
    $Script:Date                           = $Time.GetDateTimeFormats()[13]
    $Script:HtmlTemplatesPath              = Join-Path $Script:CurrPath  "templates"
    $Script:HtmlIncludesPath               = Join-Path $Script:CurrPath  "_includes"
    $Script:VersionFile                    = Join-Path $Script:RootPath 'Version.nfo'
    $Script:PushFile                       = Join-Path $Script:RootPath 'Push.nfo'
    $Script:VersionHtmlTemplate            = Join-Path $Script:HtmlTemplatesPath 'version.html.tpl'
    $Script:VersionHtml                    = Join-Path $Script:HtmlIncludesPath 'Version.html'

    $Script:HeadRev                        = git log --format=%h -1 | select -Last 1
    $Script:LastRev                        = git log --format=%h -2 | select -Last 1

   
    Write-MakeTitle "MAKE - ARSSCRIPTUM.GITHUB.IO" -c
   
    if(-not(Test-Path $Script:VersionFile)){
        throw "Missing Version File $Script:VersionFile"
    }


    [string]$VersionString = (Get-Content -Path $VersionFile -Raw)
    [SiteVersion]$CurrentVersion = [SiteVersion]::new($VersionString)
    [SiteVersion]$CurrentVersion = [SiteVersion]::new($CurrentVersion.Major,$CurrentVersion.Minor,$CurrentVersion.Build,$Script:LastRev)
    [string]$LastPush = Get-Content -Path $Script:PushFile -Raw
    $LastPush = $LastPush.Trim()
    if($Clean){

        Write-Host "Site Test dir    `t$TestPath" -f Gray;
        Write-Host "[Clear] Deleting `t$TestPath" -f DarkYellow;
        Remove-Item -Path $TestPath -Recurse -Force -ErrorAction Ignore
    }

    if($Version){
        Write-Host "RemoteBranch `t$RemoteBranch" -f Gray;
        Write-Host "CurrentBranch`t$CurrentBranch" -f DarkYellow;
        Write-Host "Site Test dir`t$TestPath" -f Gray;
        Write-Host "Curr. version`t$($CurrentVersion.ToString())" -f Gray;
        Write-Host "Pushed on    `t$LastPush" -f DarkGray;
        return
    }elseif($Merge){
        Write-Host "===============================================================================" -f DarkYellow
        Write-Host "ATTENTION - MERGE FROM $RemoteBranch TO $CurrentBranch" -f DarkRed
        Write-Host "===============================================================================" -f DarkYellow
        Read-Host "OK ? "
        git merge -Xtheirs $RemoteBranch
    }else{
        $NewVersionBuild = $CurrentVersion.Build + 1
      
        [SiteVersion]$NewVersion = [SiteVersion]::new($CurrentVersion.Major,$CurrentVersion.Minor,$NewVersionBuild,$Script:HeadRev)

        [string]$NewVersionString = $NewVersion.ToString()
        Write-Host "Curr. version`t$($CurrentVersion.ToString())" -f Gray;
        Write-Host "Pushed on    `t$LastPush" -f DarkGray;
        Write-Host "RemoteBranch `t$RemoteBranch" -f DarkGray;
        Write-Host "CurrentBranch`t$CurrentBranch" -f DarkGray;
        Write-Host "NEW  VERSION `t$NewVersionString" -f DarkYellow;
        Set-Content -Path $Script:VersionFile -Value $NewVersionString

        $VerData = Get-Content $Script:VersionHtmlTemplate
        $VerData = $VerData.Replace('__SITE_VERSION__', $NewVersionString)
        $VerData | Set-Content $Script:VersionHtml 
        Write-Host "UPDATING     `t$Script:VersionHtml" -f DarkYellow;
        
    }

    if($Push){
        $CmdPush = Get-Command 'Push-Changes'
        if($CmdPush -eq $Null){
            import-module 'PowerShell.Module.github' -Force
        }
        Set-Content -Path $Script:PushFile -Value "$Script:Date"
        Push-Changes
    }