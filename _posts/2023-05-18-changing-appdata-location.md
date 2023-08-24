---
layout: post
title:  "Changing the AppData Folder Location"
summary: "How to move AppData folder on Windows 10 - Method and Script"
author: guillaume
date: '2023-05-18'
category: ['powershell','scripts', 'win10', 'appdata', 'powershell']
tags: powershell, scripts, appdata, win10
thumbnail: /assets/img/posts/move_appdata/main.jpg
keywords: powershell, scripts, appdata, win10
usemathjax: false
permalink: /blog/move-appdata-folder-location/

---

### Overview 

The AppData folder is a folder that is created by Windows 10. It is hidden by default but can be accessed directly if a user chooses to show hidden files and folders on their system. The folder is located at the root of every user’s user folder. It contains the ```Chocolatey``` software packages and much much more.

***It can get very BIG, very FAST***

I'm approaching this subject because I have just noticed that my ```SYSTEM DRIVE``` is full and that I have already offloaded directories like **Videos, Music, Development Frameworks and Big Applications** to other bigger drives. After looking in the matter, I noticed the huge size of ```AppData```. So this is the next step in the hard-drive load sharing work.

We cannot underestimate the importance of the AppData folder on Windows 10, and the three sub-folders that it contains; Local, LocalLow, and Roaming. These folders contain other folders created by apps. Apps install to the C drive but they store user-specific data to the AppData folder e.g., Chrome’s profiles are stored in the AppData folder.


### Move AppData folder - Copy

First, let's find another location for our AppData folder; I personally switched it to the **E: drive**

```
    C:\Users\gp\AppData  ==> E:\Users\gp\AppData 
```

So I first start by creating the destination folder.

```
    $Null = New-Item -Path "E:\Users\gp\AppData" -ItemType Directory -Force
```

Second, I start the copy process. For this I use ```Robocopy``` and my [Invoke-Robocopy.ps1](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/Robocopy) script. I start a pwsh windows as Administrator so that I don't get any permissions problems during copy
and so that I can use the ```-BackupMode -Restartable``` arguments, the backup privileges functionality of Robocopy.

***Backup mode (/B)*** has to do with how robocopy reads files from the source system. It allows the copying of files on which you might otherwise get an access denied error on either the file itself or while trying to copy the file's attributes/permissions. You do need to be running in an Administrator context or otherwise have backup rights to use this flag.

***Restartable mode (/Z)*** has to do with a partially-copied file. With this option, should the copy be interrupted while any particular file is partially copied, the next execution of robocopy can pick up where it left off rather than re-copying the entire file.

That option is useful when copying very large files over a potentially unstable connection.

```
    # Launch Pwsh.exe as Admin

    $src = "C:\Users\gp\AppData"
    $dst = "F:\Users\gp\AppData"
    Invoke-Robocopy -Source $src -Destination $dst -SyncType COPY -Log "F:\Users\gp\AppData.Copy.Log" -BackupMode -Restartable 
```

### Move AppData folder - Configuration

The next step is to change the Windows 10 configuration to let him know where the AppData folder is now located.

The AppData location is set in the registry, under those 2 keys:

- **HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders**
- **HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders**

So we need to go through those values, detect the ones that need to be modified, and change them to the new values.

***POWERSHELL TO THE RESCUE!!!***


This function will list the values to change using the ```-TestOnly``` argument. Then upon confirmation, change the values to what we want.

```

    function Set-NewAppDataValues{
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, position=0)]
            [ValidateNotNullOrEmpty()]
            [string]$Path,
            [Parameter(Mandatory=$false)]
            [string]$ReplaceString = 'E:\Users\gp\AppData',
            [Parameter(Mandatory=$false)]
            [switch]$TestOnly
        )
        
        $Props = Get-Item "$RegPath"

        $AllProperties = $Props.Property

        [System.Collections.ArrayList]$ToChange = [System.Collections.ArrayList]::new()
        ForEach($p in $AllProperties){
            $Value = Get-ItemPropertyValue -Path $RegPath -Name "$p"
            $ValueSmall = $Value.ToLower()
            if($ValueSmall.Contains('f:\users\gp\appdata')){
                [void]$ToChange.Add($p)
            }
        }

        $ToChangeCount = $ToChange.Count
        if($ToChangeCount -eq 0){
            Write-Host "Found ZERO items to change." -f DarkGreen
            return;
        }
        Write-Host "Found $ToChangeCount items to change." -f DarkYellow
        Write-Host "$RegPath" -f DarkRed
        ForEach($p in $ToChange){
            [string]$Value = Get-ItemPropertyValue -Path $RegPath -Name "$p"
            [string]$ValToChange = $Value.Substring(0,19)
            
            $NewValue = $Value.Replace($ValToChange, $ReplaceString)
            try{
                if($TestOnly){
                    Write-Host "  -> [$p]" -f DarkCyan -n 
                    Write-Host " `"$NewValue`"" -f DarkGray
                }else{
                    Set-ItemProperty -Path $RegPath -Name "$p" -Value "$NewValue" -Force -ErrorAction Stop 
                    Write-Host "  -> [$p]"
                    Write-Host " DONE " -f DarkRed
                }
            }catch{
                Write-Warning "ERROR $_"
            }
        }
    }

```

We use it like so:

```
    $RegPath1 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    $RegPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    Set-NewAppDataValues $RegPath1 -TestOnly 
    Set-NewAppDataValues $RegPath2 -TestOnly 

    Read-Host "READY?"

    Set-NewAppDataValues $RegPath1  
    Set-NewAppDataValues $RegPath2  

    ----------------------------------------
	Found 13 items to change.
	HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
	  -> [AppData] "F:\Users\gp\AppData\Roaming"
	  -> [Cache] "F:\Users\gp\AppData\Local\Microsoft\Windows\INetCache"
	  -> [Cookies] "F:\Users\gp\AppData\Local\Microsoft\Windows\INetCookies"
	  -> [History] "F:\Users\gp\AppData\Local\Microsoft\Windows\History"
	  -> [Local AppData] "F:\Users\gp\AppData\Local"
	  -> [NetHood] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Network Shortcuts"
	  -> [PrintHood] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Printer Shortcuts"
	  -> [Programs] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
	  -> [Recent] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Recent"
	  -> [SendTo] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\SendTo"
	  -> [Start Menu] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Start Menu"
	  -> [Startup] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
	  -> [Templates] "F:\Users\gp\AppData\Roaming\Microsoft\Windows\Templates"
```

<center>
<img src="/assets/img/posts/move_appdata/screenshot.png" alt="screenshot" />
</center>

---------------------------------------------------------------------------------------------------------

### Fix the UWP packages

Some installed applications might need to be re-configured after this change.

Start powershell as admin:

```
	Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
```

- This will fix the start menu by adding back the applications you "deleted" in step 10
- Some packages may fail because a newer version is already installed, that's not a problem
- Some may fail because on the new user the packageds cannot be installed while they're running (notable: StartMenuExperienceHost), kill them:

```
	taskkill /F /IM explorer.exe
	taskkill /F /IM SearchApp.exe
	taskkill /F /IM SearchUI.exe
	taskkill /F /IM ShellExperienceHost.exe
	taskkill /F /IM StartMenuExperiencehost.exe
```

Some packages may still be broken, you may fix them as needed

```
    Get-AppXPackage *WindowsStore* -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
```

Now **Restart the Machine** and you are ***GOOD TO GO!***

---------------------------------------------------------------------------------------------------------


## Get the code 

[MoveAppDataFolder on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/MoveAppDataFolder)

<center>
<img src="/assets/img/posts/move_appdata/big.png" alt="info" />
</center>
