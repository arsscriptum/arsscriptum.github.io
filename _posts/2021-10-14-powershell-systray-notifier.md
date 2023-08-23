---
layout: post
title:  "System Tray Notification with PowerShell"
summary: "Spawn a system tray notification bubble with this simple function"
author: guillaume
date: '2021-10-14'
category: ['powershell','scripts', 'gui','ui']
tags: powershell, scripts, gui, ui
thumbnail: /assets/img/posts/systray-notifier/1.png
keywords: gui, ui, powershell
usemathjax: false
permalink: /blog/powershell-systray-notifier/

---

#### Show-SystemTrayNotification 

This simple function is useful when creating a PowerShell GUI app that requires some notification to the user.

```powershell

function Show-SystemTrayNotification{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Text,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Title,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$Icon,
        [Parameter(Mandatory=$false)]
        [string]$Tooltip='None',
        [Parameter(Mandatory=$false)]
        [int]$Duration=3000
    )
    Add-Type -AssemblyName System.Windows.Forms
    Write-Verbose " Add-Type -AssemblyName System.Windows.Forms"

    Write-Verbose "Show-SystemTrayNotification : Text     `"$Text`""
    Write-Verbose "Show-SystemTrayNotification : Title    `"$Title`""
    Write-Verbose "Show-SystemTrayNotification : Icon     `"$Icon`""
    Write-Verbose "Show-SystemTrayNotification : Tooltip  `"$Tooltip`""
    Write-Verbose "Show-SystemTrayNotification : Duration `"$Duration`""
    
    try{
        [System.Windows.Forms.NotifyIcon]$MyNotifier = [System.Windows.Forms.NotifyIcon]::new()
        #Mouse double click on icon to dispose
        [void](Register-ObjectEvent -ErrorAction Ignore -InputObject $MyNotifier -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action  {
            #Perform cleanup actions on balloon tip
            Write-Verbose 'Disposing of balloon'
            $MyNotifier.dispose()
            Unregister-Event -SourceIdentifier IconClicked
            Remove-Job -Name IconClicked
        })

        $MyNotifier.Icon = [System.Drawing.Icon]::new($Icon)

        if([string]::IsNullOrEmpty($Tooltip) -eq $False){
            $MyNotifier.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$Tooltip
        }
        
        $MyNotifier.BalloonTipText  = $Text
        $MyNotifier.BalloonTipTitle = $Title
        $MyNotifier.Visible = $true

        #Display the tip and specify in milliseconds on how long balloon will stay visible
        $MyNotifier.ShowBalloonTip($Duration)
    }catch{
        Write-Output $_
    }
}

```


--------------------------------------------------------------------------------------------------------


#### Test 

To quickly test the ```Show-SystemTrayNotification``` function:

1. Generate the test script ```out/Run.ps1``` by running ```./make.ps1```
2. Run ```out/Run.ps1```
3. **Or** Generate the test script **and** run the test by running ```./make.ps1 -c -r "My Title"```

```powershell
    .\make.ps1 -c

    ===============================================================================
    MAKE - SYSTRAYNOTIFIER
    ===============================================================================
    Generating "F:\Scripts\Posh.SystemTrayNotifier\out\Run.ps1"

    .\out\Run.ps1"
```
<center>
<img class="card-img-top-restricted-60"
     src="/assets/img/posts/systray-notifier/demo.gif"
     alt="make" />
</center>


--------------------------------------------------------------------------------------------------------


## Get the code 

[PowerShell.SystemTrayNotifier on GitHub](https://github.com/arsscriptum/PowerShell.SystemTrayNotifier)

