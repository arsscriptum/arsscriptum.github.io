---
layout: post
title:  "Environment Variables in PowerShell"
summary: "Change environement variables and publish to other powershell sessions"
author: guillaume
date: '2021-09-03'
category: ['powershell','scripts', 'environment']
tags: powershell, scripts, environment
thumbnail: /assets/img/posts/environment/1.png
keywords: environment, powershell
usemathjax: false
permalink: /blog/powershell-environment-vars/

---

### Introduction </h3>

If you want to have a variable that is available across sessions, that is, in every powershell windows, you need to set an environment variable.
You can set environment variables for every users on your **machine (system wide)**, which *requires administrator access*, or you can set an environment variable
for your **user only**, that will be available on each *new powershell or dos* sessions, that doesn't require administrator privileges.

---------------------------------------------------------------------------------------------------------

### Changing or Adding Environment Variables </h3>

Technically, when you add an environment value, it will be added in the Registry under these

- **USER**

```powershell
    HKEY_CURRENT_USER \ Environment
```

- **SYSTEM**

```powershell
    HKEY_LOCAL_MACHINE \ SYSTEM \ CurrentControlSet \ Control \ Session Manager \ Environment
```

All the usual ways to edit the registry are valid, and in PowerShell, you can set an environment variable using the function ```[System.Environment]::SetEnvironmentVariable``` .

```powershell
    [System.Environment]::SetEnvironmentVariable($Name,$Value,[System.EnvironmentVariableTarget]::User)
``` 

Using the following possible scopes:

```powershell
    > [Enum]::GetNames([System.EnvironmentVariableTarget])

    Process
    User
    Machine
```

### Publishing Environement Variables Changes </h3>

However, note that modifications to the environment variables do not result in immediate change. For example, if you start another PowerShell session, or another Command Prompt after making the changeanges, the environment variables will reflect the previous (not the current) values. The changes do not take effect until you log off and then log back on.

To effect these changes without having to log off, broadcast a ```WM_SETTINGCHANGE``` message to all windows in the system, so that any interested applications (such as Windows Explorer, Program Manager, Task Manager, Control Panel, and so forth) can perform an update.

For example, the following function should propagate the changes to the environment variables used in your PowerShell session:

```powershell
    function Publish-EnvironmentChanges
    {

        <#
        .SYNOPSIS
            Simulates like the Windows UI : sends a WM_SETTINGCHANGE broadcast to all Windows notifying them of the change to settings so they can refresh their config and you can do it too!
        .DESCRIPTION
            Simulates like the Windows UI : sends a WM_SETTINGCHANGE broadcast to all Windows notifying them of the change to settings so they can refresh their config and you can do it too!
            
        .PARAMETER Timeout 
           Timeout
        .PARAMETER Flags
            SMTO_ABORTIFHUNG 0x0002
            The function returns without waiting for the time-out period to elapse if the receiving thread appears to not respond or "hangs."
            SMTO_BLOCK 0x0001
            Prevents the calling thread from processing any other requests until the function returns.
            SMTO_NORMAL0x0000
            The calling thread is not prevented from processing other requests while waiting for the function to return.
            SMTO_NOTIMEOUTIFNOTHUNG 0x0008
            The function does not enforce the time-out period as long as the receiving thread is processing messages.
            SMTO_ERRORONEXIT 0x0020
            The function should return 0 if the receiving window is destroyed or its owning thread dies while the message is being processed.
        #>

        [CmdletBinding(SupportsShouldProcess)]
        param (
            [Parameter(Mandatory = $false, Position=0)]
            [int]$Timeout = 1000,
            [Parameter(Mandatory = $false, Position=1)]
            [int]$Flags = 2 # SMTO_ABORTIFHUNG: return if receiving thread does not respond (hangs)
        )
        $TypeAdded = $True
        try{
            [WinAPI.RegAnnounce]$test
        }catch{
            $TypeAdded = $False
            Write-Verbose "WinAPI.RegAnnounce not declared..."
        }

        $Result = $True
        $funcDef = @'

            [DllImport("user32.dll", SetLastError = true, CharSet=CharSet.Auto)]

             public static extern IntPtr SendMessageTimeout (
                IntPtr     hWnd,
                uint       msg,
                UIntPtr    wParam,
                string     lParam,
                uint       fuFlags,
                uint       uTimeout,
            out UIntPtr    lpdwResult
             );

    '@

        if($TypeAdded -eq $False){
             Write-Verbose "ADDING WinAPI.RegAnnounce"
            $funcRef = add-type -namespace WinAPI -name RegAnnounce -memberDefinition $funcDef
        }
        
        try{
            $HWND_BROADCAST   = [intPtr] 0xFFFF
            $WM_SETTINGCHANGE = 0x001A  # Same as WM_WININICHANGE
            $fuFlags          = $Flags  
            $timeOutMs        = $Timeout  # Timeout in milli seconds
            $res              = [uIntPtr]::zero

            # If the function succeeds, this value is non-zero.
            $funcVal = [WinAPI.RegAnnounce]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::zero, "Environment", $fuFlags, $timeOutMs, [ref] $res);

            if ($funcVal -eq 0) {
               throw "SendMessageTimeout did not succeed, res= $res"
            }
            else {
               write-Verbose "Message sent"
               return $True
            }
        }
        catch{
            $Result = $False
            Write-Error $_
        }
        return $Result
    }
```

### Set-EnvironmentVariable </h3>


Wrapping things up, to set an environment variable, this helper function will be useful :


```powershell
    Function Set-EnvironmentVariable{
        [CmdletBinding(SupportsShouldProcess)]
            param(
            [parameter(mandatory=$true, Position=0)]
            [String]$Name,
            [parameter(mandatory=$true, Position=1)]
            [String]$Value,
            [parameter(mandatory=$false)]
            [ValidateSet('User', 'Machine', 'Session', 'UserSession')]
            [String]$Scope='UserSession'
            )
        switch($Scope.ToLower())
        {
            { 'session','usersession' -eq $_ } 
            { 
                $CurrentSetting=( Get-ChildItem -Path env: -Recurse | % -process { if($_.Name -eq $Name) {$_.Value} })
             
                if(($CurrentSetting -eq $null) -Or ($CurrentSetting -ne $null -And $CurrentSetting.Value -ne $Value)){
                    Write-Verbose "Environment Setting $Name is not set or has a different value, changing to $Value"
                    $TempPSDrive = $(get-date -Format "temp\hhh-\mmmm-\sss")
                    new-psdrive -name $TempPSDrive -PsProvider Environment -Root env:| Out-null
                    $NewValPath=( "$TempPSDrive" + ":\$Name")
                    Remove-Item -Path $NewValPath -Force -ErrorAction Ignore | Out-null
                    New-Item -Path $NewValPath -Value $Value -Force -ErrorAction Ignore | Out-null
                    Remove-PSDrive $TempPSDrive -Force | Out-null
                }
            }
            { 'user','usersession' -eq $_ } 
            { 
                Write-Verbose "Setting $Name --> $Value [User]"
                [System.Environment]::SetEnvironmentVariable($Name,$Value,[System.EnvironmentVariableTarget]::User)
            }
            { 'machine' -eq $_ }
            {  
                Write-Verbose "Setting $Name --> $Value [Machine]"
                [System.Environment]::SetEnvironmentVariable($Name,$Value,[System.EnvironmentVariableTarget]::Machine)
            }
        }
        Publish-EnvironmentChanges
}


```