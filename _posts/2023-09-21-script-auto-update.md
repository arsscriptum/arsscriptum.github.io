---
layout: post
title:  "PowerShell Script autoUpdate"
summary: "Having a script check for it's latest version and auto update and relauch if available"
author: guillaume
date: '2023-09-20'
category: ['powershell','scripts', 'update', 'git', 'autoupdate']
tags: powershell, scripts, regex, regular, 'git', 'autoupdate'
thumbnail: /assets/img/posts/script-auto-update/main.png
keywords: powershell, scripts, update, autoupdate
usemathjax: false
permalink: /blog/script-auto-update/

---


# Auto Update for PowerShell scripts

This script will check the remote repository to se if there's a new version of he current script file, if so, it will update it and re-run it.

Initializaton, get the git exe path and the current script path

```powershell
  $GitCmd = (Get-Command "git.exe")
  if($Null -eq $GitCmd){ throw "git.exe not found" }
  $GitExe = $GitCmd.Source
  $ScriptPath = "$PSCommandPath"
```

Get the branches names for the local and the remote branch...


``powershell
  $RemoteBranch = & "$GitExe" 'for-each-ref' '--format=%(upstream:short)' "`"$(git symbolic-ref -q HEAD)`""
  $LocalBranch  = & "$GitExe" 'branch' '--show-current'
``


Get the current number of new revisions available, 0 if we are up to date

```powershell
  [uint32]$NewVers = & "$GitExe" 'diff' "$RemoteBranch..$LocalBranch"  "$ScriptPath" | Measure-Object -Line | Select -ExpandProperty Lines
```

## How to test

1. Clone the repo at 2 different locations
2. Update the AutoUpdate.ps1 script in one location (location 1) and ```commit/push```
3. Go to location #2, and run ```. .\AutoUpdate.ps1```

You will get this:

```powershell
  > . .\AutoUpdate.ps1

  This script was updated and will restart.
  Hello World
```


-------------------


```powershell
  function Test-NewScriptVersion{
    [CmdletBinding(SupportsShouldProcess)]
    param() 

    begin{
      try{
        $GitCmd = (Get-Command "git.exe")
        if($Null -eq $GitCmd){ throw "git.exe not found" }
        $GitExe = $GitCmd.Source
        $ScriptPath = "$PSCommandPath"
        if(-not(Test-Path -Path "$ScriptPath")){ throw "file not found" }
      }catch{
        write-error "$_"
      }
    }
    process{
      try{
        $RemoteBranch = & "$GitExe" 'for-each-ref' '--format=%(upstream:short)' "`"$(git symbolic-ref -q HEAD)`""
        $LocalBranch  = & "$GitExe" 'branch' '--show-current'
        Write-Verbose "Remote Branch: `"$RemoteBranch`""
        Write-Verbose "Local  Branch: `"$LocalBranch`""
        $Output = & "$GitExe" 'fetch' *> "$ENV:Temp\gitout.txt" | Out-Null
        $HeadRev = & "$GitExe"  'log' '-n' '1' '--no-decorate' '--pretty=format:%H'  "$ScriptPath"
        $Ret = $False
        [uint32]$NewVers = & "$GitExe" 'diff' "$RemoteBranch..$LocalBranch"  "$ScriptPath" | Measure-Object -Line | Select -ExpandProperty Lines
        if($NewVers -gt 0){
            Write-Verbose "A new version is available for `"$ScriptPath`"" 
            Write-Verbose "Head Rev: `"$HeadRev`""
            $Ret = $True
            
        }else{
             Write-Verbose "No updates for `"$ScriptPath`"" 
             Write-Verbose "Head Rev: `"$HeadRev`"" 
        }

        $Ret
      }catch{
        write-error "$_"
      }
    }
  }


  function Update-ScriptVersion{
    [CmdletBinding(SupportsShouldProcess)]
    param() 

    begin{
      try{
        $GitCmd = (Get-Command "git.exe")
        if($Null -eq $GitCmd){ throw "git.exe not found" }
        $GitExe = $GitCmd.Source
        $ScriptPath = "$PSCommandPath"
        if(-not(Test-Path -Path "$ScriptPath")){ throw "file not found" }
        $DirName = (Get-Item -PAth "$ScriptPath").DirectoryName
      }catch{
        write-error "$_"
      }
    }
    process{
      try{
        pushd "$DirName"
        $Output = & "$GitExe" 'pull' > "$ENV:Temp\gitout.txt" | Out-Null
        popd
      }catch{
        write-error "$_"
      }
    }
  }


  $NewVersionAvailable = Test-NewScriptVersion
  if($NewVersionAvailable){
    Update-ScriptVersion

    Write-Host "This script was updated and will restart."
    Start-Sleep 1
    . "$ScriptPath"
    # Start-Process pwsh.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath)
    Exit
  }

```


-------------------


<br>


## Get the code 

[AutoUpdateScript on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/AutoUpdateScript)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**