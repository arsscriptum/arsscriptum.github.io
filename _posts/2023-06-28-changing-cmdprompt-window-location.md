---
layout: post
title:  "Changing Cmd Prompt Window Location"
summary: "How to programatically configure the size and location of the Cmd Prompt Window for certain Apps?"
author: guillaume
date: '2023-06-28'
category: ['powershell','scripts', 'win10', 'appdata', 'powershell']
tags: powershell, scripts, appdata, win10
thumbnail: /assets/img/posts/cmd_sizepos/main.png
keywords: powershell, scripts, appdata, win10
usemathjax: false
permalink: /blog/configure-cmdprompt-window-properties/

---

### Overview 

If you have been using and observing Command Prompt for a while, you must be aware that the Command prompt always opens at a fixed position on the desktop and has a fixed window size. Sometimes, the default window size of the command prompt is either too small or too large. Again, sometimes, the command prompt is not properly positioned on the desktop. Sometimes it is on the center, whereas sometimes, it goes at extreme corners. 

***Why I talk about this ?***

I recently added a Scheduled Task that launches a ```batch file``` when a user logs in. This script creates a dark window on desktop when the user ener his session and it's bothering, it creates confusion, people try to close it, etc... I wanted to have a way to configure the window position/size using a simple PowerShell script.

### Steps To Manually Change The Command Prompt Window Position on Desktop on Windows 10

1. Open Command prompt. Then right click on the uppermost panel. Go to Properties.<br>
2. ![Screenshot](/assets/img/posts/cmd_sizepos/cmd-rtclk.jpg)<br>
3. Go to Layout tab. In the Layout tab, you will find parameters for the Command prompt Window position. You can change the left and top position of window size if you want.<br>
4. ![Screenshot](/assets/img/posts/cmd_sizepos/cmd-winsz.png)<br>
5. Now, close the Properties window. Right click on the title bar of the Command Prompt window, select Defaults from the context menu. The Propertied window will open once again. You can now check the updated window position.<br>

<center>
<img src="/assets/img/posts/cmd_sizepos/cmd-rtclk.jpg" alt="info" />
</center>

<br>

<center>
<img src="/assets/img/posts/cmd_sizepos/cmd-winsz.png" alt="info" />
</center>

<br>

---------------------------------------------------------------------------------------------------------

### Change The Command Prompt Window Position Programatically

After Searching the Registry for settings changes, I found out that the Console Window Properties are saved in this registry location:

```
    HKEY_CURRENT_USER\Console\ <application name> \ * 
```

We only want to set the **window size** and the **window position** , so that we can set a position outside the view of the user and set the size as very small. So only 2 settings are importan to us:

1) WindowPosition *HKEY_CURRENT_USER\Console\{application name}\WindowSize*

2) WindowSize *HKEY_CURRENT_USER\Console\{application name}\WindowPosition*


First to set the properties for a specific application, we must create the registry entry for it. ***The Registry entry name is based of the application path*** . 

Here's how to get it:


```
    # Replace the backslashes with underscores in the app path like so:
    $RegEntryName = $Path.Replace("\","_")

    #Example
    $Path = "c:\xampp\apache_start.bat"
    $RegEntryName = $Path.Replace("\","_")
    $RegEntryName

    E:_xampp_apache_start.exe

    # The Registry Enry is
    HKEY_CURRENT_USER\Console\E:_xampp_apache_start.exe

    $RegPath = "HKCU:\Console\{0}" -f $RegEntryName
```

<center>
<img src="/assets/img/posts/cmd_sizepos/screenshot.png" alt="screenshot" />
</center>

<br>

### Window Size

Now we need to calculate the Window Size. This is set with a hexadecimal value composed of two values (x,y)

***Here I set the size of the window to 1x1***

```
    
    # Set the window size to 1x1

      0x0001      0x0001
    |--------|  |--------|
      Size X      Size Y


    So Final Value  0x00010001
                    |----|----| 

    # To set the decimal value, I convert like so
    [int]$SizeValue = [int32]"0x00010001"
    $Null = New-ItemProperty -Path "$RegPath" -Name "WindowSize" -PropertyType DWORD -Value $SizeValue

```

<center>
<img src="/assets/img/posts/cmd_sizepos/screenshot3.png" alt="screenshot" />
<br>
</center>
<br>

### Window Position

Lastly, ***we set the Window Position*** . Same as with the size, the value is compsed of 2 hex values concatenated together, representing the x and y positions of the location.

Theres a difference though : we need to base our value on the window size, or screen resolution. So that if my screen is 1920x1080, the position must be in that range.

Here's how I do it:

1) Get the current screen resolution<br>
2) Remove 4 from both the horizontal and vertical values, so that the position is far, but still in range.<br>
3) Create 2 hex values and merge them to get a final hex value representing the position. Example: 0x0434 and 0x077c , giving us a merged value of 0x0434977c<br>
4) Convert the hex value to decimal and set that value in the registry. [Int32]"0x0434977c" equals 70555516<br>


Here's a function ```Get-PositionValueFromResolution``` with a lot of Verbose logs to explain how it works. See Screenshot below.

```
  function Get-PositionValueFromResolution{
       [CmdletBinding(SupportsShouldProcess)]
       param()

       $MaxResHor = (Get-CurrentResolution | Select -ExpandProperty Horizontal | Measure-Object -Maximum).Maximum
       $MaxResVer = (Get-CurrentResolution | Select -ExpandProperty Vertical | Measure-Object -Maximum).Maximum
       Write-Verbose "From Resolution: ResHor $MaxResHor"
       Write-Verbose "From Resolution: ResVer $MaxResVer"
       $MaxResHor = $MaxResHor - 4 
       $MaxResVer = $MaxResVer - 4
       $HexHor = ([System.Convert]::ToString($MaxResHor,16).PadLeft(4,'0'))
       $HexVer = ([System.Convert]::ToString($MaxResVer,16).PadLeft(4,'0'))
       Write-Verbose "MaxResHor $MaxResHor. $HexHor"
       Write-Verbose "MaxResVer $MaxResVer. $HexVer"

       $FinalHexVal = '0x{0}{1}' -f $HexVer,$HexHor
       Write-Verbose "Final Hex Value   $FinalHexVal"
       
       $NumValue = [Int32]"$FinalHexVal"
       Write-Verbose "Decimal Value     $NumValue"
       $NumValue
    }
```

<center>
<img src="/assets/img/posts/cmd_sizepos/screenshot2.png" alt="screenshot" />
<br>
</center>

<br>

Putting it all together, we get this function:

```
  function Set-AppConsoleProperties {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [Parameter(Mandatory=$True, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [string]$Path
        )
        try{
            if(-not(Test-Path "$Path")){ throw "no such file"}
            $ModPath = $Path.Replace("\","_")
            $RegPath = "HKCU:\Console\{0}" -f $ModPath
            $Null = New-Item -Path "$RegPath" -Force -ErrorAction Ignore

            [int]$SizeValue = [int32]"0x00010001"
            $Null = New-ItemProperty -Path "$RegPath" -Name "WindowSize" -PropertyType DWORD -Value $SizeValue

            [BigInt]$Val = Get-PositionValueFromResolution
            $Null = New-ItemProperty -Path "$RegPath" -Name "WindowPosition" -PropertyType DWORD -Value $Val
        }catch{
            Write-Error "$_"
        }
    }
```

<br>
---------------------------------------------------------------------------------------------------------

### Set Registry Values for all Users at the same time

Since the values we are changing are located in ```HKEY_CURRENT_USER``` . We can go through all the Users in the Registry Path ```HKEY_USERS``` to set the
values for all of them in one go. We need to be admin for this. See function ```Set-AppConsolePropertiesForAllUsers``` 


```
  function Set-AppConsolePropertiesForAllUsers {
      [CmdletBinding(SupportsShouldProcess)]
      param (
          [Parameter(Mandatory=$True, Position = 0)]
          [ValidateNotNullOrEmpty()]
          [string]$Path
      )
      try{
          if(-not(Test-Path "$Path")){ throw "no such file"}
          $ModPath = $Path.Replace("\","_")
          New-PSDrive HKU Registry HKEY_USERS
          $UserNames = Get-LocalUser | Where Enabled -eq $True | Select -ExpandProperty Name
          ForEach($user in $UserNames){
              $Sid =  (Get-UserSID $user).SID
              $RegPathRoot = "HKU:\{0}\Console" -f $Sid
              if(Test-Path $RegPathRoot){
                  Write-Host "Found `"$RegPathRoot`""
                  
                  $RegPath = "{0}\{1}" -f $RegPathRoot, $ModPath
                  $Null = New-Item -Path "$RegPath" -Force -ErrorAction Ignore

                  [int]$SizeValue = [int32]"0x00010001"
                  $Null = New-ItemProperty -Path "$RegPath" -Name "WindowSize" -PropertyType DWORD -Value $SizeValue

                  [BigInt]$Val = Get-PositionValueFromResolution
                  $Null = New-ItemProperty -Path "$RegPath" -Name "WindowPosition" -PropertyType DWORD -Value $Val
              }
          }
        

          Remove-PSDrive HKU
      }catch{
          Write-Error "$_"
      }
  }
```
<br>
---------------------------------------------------------------------------------------------------------


## Get the code 

[SetCmdWindowProperties on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/SetCmdWindowProperties)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**