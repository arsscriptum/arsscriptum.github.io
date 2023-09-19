---
layout: post
title:  "Running an Interactive XAMPP Web Server"
summary: "How to setup an Interactive Web Server using XAMPP and PowerShell"
author: guillaume
date: '2023-06-27'
category: ['powershell','scripts', 'win10', 'appdata', 'powershell']
tags: powershell, scripts, xampp, win10
thumbnail: /assets/img/posts/xampp_interactive_server/main.jpg
keywords: powershell, scripts, xampp, win10
usemathjax: false
permalink: /blog/setup-interactive-xampp-server/

---

### Overview 

The main reason behind me setting up an ***Interactive*** XAMPP Web Server is so that I can use a **Web Shell** that I hae been developping. The Web Shell has functionalities like

1) Run PowerShell scripts
2) Run Executable files
3) Manage files (upload/download/delete/zip)
4) Run a cmd window

The Web Shell is written in PHP. The processes executed when using the Web Shell are run under the user that run **httpd.exe** . But furthermore, and very important : the process needs to be launched as part of an interactive session. Else, we won't be able to run scripts, get screenshots and all other functionalities that requires intraction with the desktop.

This is pretty simple if I just launch the XAMPP Control Panel and start Apache manually, but I want to automate this. Make sure that whenever a user logs in, an interactive web server is started.


### Using Scheduled Tasks to Launch httpd.exe

We can create some sheduled tasks (one per local users), with the ***LogonType*** set to **Interactive** and the process started with them will be able to interact with the desktop.
I have made 2 functions to create such tasks. One that runs a batch file / executable, the others that runs an encoded task:

**Runs an Executable / Batch File**

```
  function Install-BatchFileScriptTask {
      [CmdletBinding(SupportsShouldProcess)]
      param (
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$RunFile,
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$UserName
      )

      $action = New-ScheduledTaskAction -Execute "$RunFile"
      $TaskName = "Run {0} for {1} - Interactive" -f ((Get-Item $RunFile).Name), $UserName
      $trigger = New-ScheduledTaskTrigger -AtLogOn
      
      $settings = New-ScheduledTaskSettingsSet -Priority 10
      
      $principal = New-ScheduledTaskPrincipal -UserID "$env:userdomain\$UserName" -LogonType Interactive -RunLevel Highest
      $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
      $Res=Register-ScheduledTask $TaskName -InputObject $task -User $username 

      Set-AppConsolePropertiesForAllUsers -Path "$RunFile"

      return "$TaskName"
  }
```

**Runs an Encoded Command**

```
  function Install-EncodedScriptTask {
      [CmdletBinding(SupportsShouldProcess)]
      param (
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$EncodedTask,
          [Parameter(Mandatory)]
          [ValidateNotNullOrEmpty()]
          [string]$UserName
      )

      $EncodedTaskLen=$EncodedTask.Length
      Write-Host "Install-EncodedScriptTask called with taskname $TaskName. Code: EncodedTask ($EncodedTaskLen chars)"
      $PwExe = (Get-Command 'pwsh.exe').Source
      $action = New-ScheduledTaskAction -Execute "$PwExe" -Argument "-ExecutionPolicy Unrestricted -WindowStyle Hidden -EncodedCommand `"$EncodedTask`""
      $TaskName = "Run {0} for {1} - Interactive" -f ((Get-Item $RunFile).Name), $UserName
      $trigger = New-ScheduledTaskTrigger -AtLogOn
      
      $settings = New-ScheduledTaskSettingsSet -Priority 10
      
      $principal = New-ScheduledTaskPrincipal -UserID "$env:userdomain\$UserName" -LogonType Interactive -RunLevel Highest
      $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
      $Res=Register-ScheduledTask $TaskName -InputObject $task -User $username 
      return "$TaskName"
  }

```

One just needs to run this as Administrator, and one task will e create for every local user. When they log in, a web server will be started, and you will be able to run a Web Shell on it.

```
    $AllLocalAcounts = Get-LocalUser | Where Enabled -eq $True | Select -ExpandProperty Name

    ForEach($user in $AllLocalAcounts){
        Write-Host "Create Scheduled Task for user `"$user`"" -f DarkYellow
        $TaskName = Install-BatchFileScriptTask -RunFile $RunFile -UserName "$user"
        #Start-ScheduledTask -TaskName "$TaskName"
    }
```

---------------------------------------------------------------------------------------------------------


## Get the code 

[XamppInteractiveServer on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/XamppInteractiveServer)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**