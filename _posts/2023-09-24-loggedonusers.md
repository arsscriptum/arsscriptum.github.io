---
layout: post
title:  "SysInternal PsLoggedOn PowerShell Integration"
summary: "Get both the locally logged on users and users logged on via resources for either the local computer, or a remote one"
author: guillaume
date: '2023-09-24'
category: ['powershell','scripts', 'update', 'sysinternals', 'psloggedon']
tags: powershell, scripts, 'sysinternals', 'psloggedon'
thumbnail: /assets/img/posts/loggedonusers/main.png
keywords: powershell, scripts, sysinternals, psloggedon
usemathjax: false
permalink: /blog/loggedonusers/

---

## Overview

You can determine who is using resources on your local computer with the "net" command ("net session"), however, there is no built-in way to determine who is using the resources of a remote computer. In addition, NT comes with no tools to see who is logged onto a computer, either locally or remotely. **PsLoggedOn** is an applet that displays both the locally logged on users and users logged on via resources for either the local computer, or a remote one. If you specify a user name instead of a computer, **PsLoggedOn** searches the computers in the network neighborhood and tells you if the user is currently logged on.

**PsLoggedOn**'s definition of a locally logged on user is one that has their profile loaded into the Registry, so **PsLoggedOn** determines who is logged on by scanning the keys under the HKEY_USERS key. For each key that has a name that is a user SID (security Identifier), **PsLoggedOn** looks up the corresponding user name and displays it. To determine who is logged onto a computer via resource shares, **PsLoggedOn** uses the NetSessionEnum API. Note that **PsLoggedOn** will show you as logged on via resource share to remote computers that you query because a logon is required for **PsLoggedOn** to access the Registry of a remote system.

**PsLoggedOn** is part of a growing kit of Sysinternals command-line tools that aid in the administration of local and remote systems named PsTools.



-----------------------



## Install-PsLoggedOn

Install the ```PsLoggedOn.exe``` Program

```powershell

  function Install-PsLoggedOn { 
      [CmdletBinding(SupportsShouldProcess)]
      param(
          [Parameter(Mandatory=$False)]
          [string]$DestinationPath
      )
      begin{
          if([string]::IsNullOrEmpty($DestinationPath)){
              $DestinationPath = "{0}\psloggedon" -f "$PSScriptRoot"
          }
          if(-not(Test-Path -Path "$DestinationPath" -PathType Leaf)){ 
              $Null = New-Item -Path "$DestinationPath" -ItemType Directory -Force -ErrorAction Ignore
          }
          
      }
      process{
        try{
          $Url = "https://download.sysinternals.com/files/PSTools.zip"
          $TmpPath = "$ENV:Temp\{0}" -f ((Get-Date -UFormat %s) -as [string])
          Write-Verbose "Creating Temporary path `"$TmpPath`"" 
          $Null = New-Item -Path "$TmpPath" -ItemType Directory -Force -ErrorAction Ignore
          $DownloadedFilePath = "{0}\PSTools.zip" -f $TmpPath

          Write-Verbose "Saving `"$Url`" `"$DownloadedFilePath`" ... " 
          $ppref = $ProgressPreference
          $ProgressPreference = 'SilentlyContinue'
          $Results = Invoke-WebRequest -Uri $Url -OutFile $DownloadedFilePath -PassThru
          $ProgressPreference = $ppref 
          if($($Results.StatusCode) -ne 200) {  throw "Error while fetching package $Url" }

          Write-Verbose "Extracting `"$DownloadedFilePath`" ... " 
          
          $Files = Expand-Archive -Path $DownloadedFilePath -DestinationPath $TmpPath -Force -Passthru | Where Name -Match "PsLoggedOn"
          ForEach($f in $Files.Fullname){
              Copy-Item -Path "$f" -Destination "$DestinationPath" -Force
          }
          $InstalledFilePath = "{0}\PsLoggedon64.exe" -f $DestinationPath
          if(-not(Test-Path -Path "$InstalledFilePath" -PathType Leaf)){ throw "install error" }
          $InstalledFilePath
        }catch{
          throw $_
        }
      }
  }
```




-----------------------



## Search-PsLoggedOnApp

Search for the  ```PsLoggedOn.exe``` Program on the computer

```powershell

  function Search-PsLoggedOnApp { 
      [CmdletBinding(SupportsShouldProcess)]
      param()

      begin{
          
          [string]$CurrentPath = "$PSScriptRoot"
          $SearchLocations = @("$CurrentPath", "$ENV:Temp", "$ENV:ProgramFiles")

      }
      process{
        try{
          $PsLoggedon64Exe = ""
          $Cmd = Get-Command "PsLoggedon64.exe"
          if($Cmd -ne $Null){
              $PsLoggedon64Exe = $Cmd.Source
              Write-Verbose "Found `"$PsLoggedon64Exe`" in PATH"
          }else{
              [string[]]$SearchResults = ForEach($dir in $SearchLocations){
                  Write-Verbose "Searching in `"$dir`""
                  Get-ChildItem -Path "$dir" -File -Recurse -Filter "PsLoggedon64.exe" -Depth 2 -ErrorAction Ignore | Select -ExpandProperty Fullname
              }
              $SearchResultsCount = $SearchResults.Count
              if($SearchResultsCount -gt 0){
                  $PsLoggedon64Exe = $SearchResults[0]
                  Write-Verbose "Found $SearchResultsCount Results. Using `"$PsLoggedon64Exe`""
              }
          }
          
          $PsLoggedon64Exe
        }catch{
          throw $_
        }
      }
  }
```



-----------------------



## Get-LoggedOnUsers

Get the list of logged on users using the ```PsLoggedOn.exe``` Program. Parse the output in ```PsCustomObjects```

```powershell

  function Get-LoggedOnUsers { 
      [CmdletBinding(SupportsShouldProcess)]
      param(
          [Parameter(Position = 0, Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Computer Name")]
          [string]$ComputerName
      )
      begin{
          # was a remote computer specified ?
          $ComputerSpecified = ($False -eq ([string]::IsNullOrEmpty($ComputerName)))
          Write-Verbose "ComputerSpecified `"$ComputerSpecified`""
          if($ComputerSpecified -eq $True){
              # if a remote machine was specified, try to connect to it first, if it failes, no need to go further...
              $ComputerAvailable =Test-Connection -TargetName  "$ComputerName" -Ping -Count 1 -IPv4 -Quiet
              Write-Verbose "Connecting to `"$ComputerName`" - ComputerAvailable $ComputerAvailable"
              if(-not($ComputerAvailable)){ throw "canot connect to `"$ComputerName`""}
          }
          # Search fot PSLoggedOn program...
          [string]$PsLoggedon64Exe = Search-PsLoggedOnApp
          if([string]::IsNullOrEmpty($PsLoggedon64Exe)){
              # Install it if no existant
              Write-Verbose "Canot find PsLoggedOn, Installing PsLoggedOn"
              $PsLoggedon64Exe = Install-PsLoggedOn
              Write-Verbose "Using `"$PsLoggedon64Exe`""
          }
          if(-not(Test-Path -Path "$PsLoggedon64Exe" -PathType Leaf)){ 
              throw "cannot find psloggedon"
          }
      }
      process{
        try{
          # Execute the program and parse the output
          [System.Collections.ArrayList]$Users = [System.Collections.ArrayList]::new()
          if($ComputerSpecified -eq $True){
              [string[]]$Output = &"$PsLoggedon64Exe" "\\$ComputerName" "-nobanner"
          }else{
              [string[]]$Output = &"$PsLoggedon64Exe" "-nobanner"
          }
          [uint32]$OutputCount = $Output.Count
          if($OutputCount -le 2){ throw "invalid data" }
          ForEach($line in $Output){
              if($line -match '^(?<FourSpaces>( ){4})'){
                  $trimmed_line = $line.TrimStart()
                  [string[]]$substr = $trimmed_line.Split("`t")
                  [String]$DateStr = $substr[0].Trim()
                  Write-Verbose "DateStr `"$DateStr`""
                  
                  [string]$UserName = $substr[$substr.Count - 1].Trim()
                  Write-Verbose "UserName `"$UserName`""
                  if(-not([string]::IsNullOrEmpty($UserName))){
                      [PsCustomObject]$o = [PsCustomObject]@{
                          LoginTime = $DateStr
                          UserName = $UserName
                      }
                      [void]$Users.Add($o)
                  }   
              }
          }
          $Users
         
        }catch{
          throw $_
        }
      }
  }
```




-----------------------



## Example Usage

Here's a test function using the function above

```powershell

  function Test-GetLoggedOnUsers { 
      [CmdletBinding(SupportsShouldProcess)]
      param()

      process{
        try{
          Write-Hosts "Retrieving Local LoggedOn Users..."
          $local = Get-LoggedOnUsers
          $CsvData = $local | ConvertTo-Csv
          
          $ExportPath = "{0}\export" -f "$PSScriptRoot"
          $Null = New-Item -Path "$ExportPath" -ItemType Directory -Force -ErrorAction Ignore
          $ExportFilePath = "{0}\LocalUsers.csv" -f $ExportPath
          Write-Hosts "Exporting Local LoggedOn Users to `"$ExportFilePath`""
          Set-Content -Path "$ExportFilePath" -Value $CsvData -Force -ErrorAction Ignore

          Write-Hosts "------------------------------------------------"
          Write-Hosts "Get-LoggedOnUsers `"DESKTOP-JIRMI11`""
          

          Write-Hosts "Retrieving Remote LoggedOn Users..."
          $RemoteUsers = Get-LoggedOnUsers "DESKTOP-JIRMI11"
          $CsvData = $local | ConvertTo-Csv
          
          $ExportPath = "{0}\export" -f "$PSScriptRoot"
          $Null = New-Item -Path "$ExportPath" -ItemType Directory -Force -ErrorAction Ignore
          $ExportFilePath = "{0}\RemoteUsers.csv" -f $ExportPath
          Write-Hosts "Exporting Remote LoggedOn Users to `"$ExportFilePath`""
          Set-Content -Path "$ExportFilePath" -Value $CsvData -Force -ErrorAction Ignore
          Write-Host "Done!" -f Green
         
        }catch{
          throw $_
        }
      }

  }

```



-------------------


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/loggedonusers/demo.ps1" alt="table" />
</center>
<br>




-----------------------



## Installing PSLoggedOn

The installation is done automatically if the file is not locacted on the computer. It is very fast. 

1. Downloads the ```https://download.sysinternals.com/files/PSTools.zip``` packages from sysinternals.
2. Unpack the files to TEMP folder
3. Copy the PsLoggedOn.exe Program to Destination folder.

### Example


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/loggedonusers/install.ps1" alt="table" />
</center>
<br>



