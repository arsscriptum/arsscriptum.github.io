---
layout: post
title:  "Search Registry for Entry Names"
summary: "Search in the registry recursively and replace values when found"
author: guillaume
date: '2021-11-22'
category: ['powershell','scripts', 'registry']
tags: powershell, scripts, environment
thumbnail: /assets/img/posts/search_reg/1.png
keywords: registry, powershell
usemathjax: false
permalink: /blog/powershell-search-registry-recursively/

---

### Introduction </h3>


This is a small function to search in the registry **recursively** for all entries matching a specified name. Using this information, you can replace all the 
values found. This post also contains a function to add registry values in a specified path to test the search function.



---------------------------------------------------------------------------------------------------------


### Search Registry Recursively </h3>

```powershell
    function Test-RegistryValue{
        param (
            [Parameter(Mandatory = $true, Position=0)]
            [String]$Path,
            [Parameter(Mandatory = $true, Position=1)]
            [Alias('Entry')]
            [ValidateNotNullOrEmpty()]$Name
        )

        if(-not(Test-Path $Path)){
            return $false
        }
        $props = Get-ItemProperty -Path $Path -ErrorAction Ignore
        if($props -eq $Null){return $False}
        $value =  $props.$Name
        if($null -eq $value -or $value.Length -eq 0) { return $false }

        return $true
       
    }



    function Get-EntriesRecursively {
    <#
        .Synopsis
         Get the list of entries recursively from the registry
        .Description
        Get the list of entries recursively from the registry, given a property name and root path
        .Parameter Path
         Registry path
        .Parameter Name
        The entry name to search
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param (
         [parameter(Mandatory=$true)]
         [string]$Path,
         [parameter(Mandatory=$true)]
         [string]$Name,
         [parameter(Mandatory=$false)]
         [System.Collections.ArrayList]$Results
        )
        
        try{
            $CurrentDepth = 1
            if($Results -eq $Null){
                Set-Variable -Name "RegRoot" -Value "$Path" -Scope Global -ErrorAction Ignore
                $Results = [System.Collections.ArrayList]::new()
            }else{
                $CurrentDepth = [regex]::matches($($Path.Replace($(Get-Variable -Name "RegRoot" -ValueOnly),'')),"\\").Count
            }
            $AllChilds=(Get-Item "$Path\*").PSChildName
            $AllChildsCount=$AllChilds.Count
            if($AllChildsCount -gt 0){
                $Spaces = '    '
                For($i = 0 ; $i -lt $CurrentDepth ; $i++){$Spaces += '    '}   
                Write-Verbose "$Spaces|---| + $AllChildsCount subkey in $Path"
            }
            foreach($Entry in $AllChilds){
                $exists=Test-RegistryValue "$Path\$Entry" "$Name"
                if($exists){
                    $Value=(Get-ItemProperty "$Path\$Entry")."$Name"
                    Write-Verbose "    $Spaces---> Found $Name [$Value]"
                    [pscustomobject]$o = @{
                        Path = "$Path\$Entry"
                        Name = $Name
                        Value = $Value
                    }

                    $Null = $Results.Add($o)    
                }

                $c = (Get-Item "$Path\$Entry\*").Count
                if($c -gt 0){
                    $Null = Get-EntriesRecursively -Path "$Path\$Entry" -Name $Name -Results $Results
                }
            }

            return $Results
            
        }catch{
            Write-Error "$_"

        }
    }
```

### New-TestEntries </h3>


In order to test the search function above, this helper function will be useful :


```powershell
     
    [CmdletBinding(SupportsShouldProcess)]
        param (
            [parameter(Mandatory=$false)]
            [string]$Path = "HKCU:\SOFTWARE\DevelopmentSandbox\TestSettings",
            [parameter(Mandatory=$false)]
            [int]$NumEntries = 10,
            [parameter(Mandatory=$false)]
            [int]$MaxDepth = 5,
            [parameter(Mandatory=$false)]
            [switch]$BogusEntries,
            [parameter(Mandatory=$false)]
            [switch]$Test,
            [parameter(Mandatory=$false)]
            [switch]$StartRegEd
        )

    try{

        $TestMode = $False        
        if ( ($PSBoundParameters.ContainsKey('WhatIf') -Or $Test) ){         
            $TestMode = $True
        }

        $TotalEntries = 0
        Write-Host "Root Path " -f Red -n ; Write-Host "[$Path]" -f Gray
        New-Item -Path $Path -ItemType 'Directory' -Force  -ErrorAction Ignore | Out-null

        Get-Random -SetSeed $(Get-Date -UFormat %s) | Out-null
        $p = '' 
        $Noise = [System.Collections.ArrayList]::new()
        $DepthValues = Get-Random -Maximum $MaxDepth -Minimum 1 -Count $numEntries
        ForEach($Depth in $DepthValues){
            $p = $Path
            $rel = '/'
            [string]$s = (New-Guid).Guid 
            [string[]]$sa = $s.Split('-') 
            # valid use?
            For($j = 0 ; $j -lt $Depth ; $j++){
                $p = Join-Path $p $sa[$j]
                $rel = Join-Path $rel $sa[$j]

                if($BogusEntries){
                    $n1 = "Guid_$j"
                    $n2 = "Date_$j"
                    $v1 = $((New-Guid).Guid)
                    $v2 = $((Get-Date).GetDateTimeFormats()[$j])

                    if(-not $TestMode){
                        New-Item -Path $p -Force | Out-null
                        New-ItemProperty -Path $p -Name $n1 -Value $v1 -PropertyType 'String'  | Out-null
                        New-ItemProperty -Path $p -Name $n2 -Value $v2 -PropertyType 'String'  | Out-null

                        Write-Verbose "`t+$p"
                        Write-Verbose "`t===> $n1 / $v1"
                        Write-Verbose "`t===> $n2 / $v2"
                        $Null = $Noise.Add(@{
                            Path = $p
                            Name = $n1
                            Value = $v1
                        })
                        $Null = $Noise.Add(@{
                            Path = $p
                            Name = $n2
                            Value = $v2
                        })                  
                    }else{
                        Write-Host -n -f DarkRed "[TestMode] "
                        Write-Host -n -f Gray "$p"
                        Write-Host -f DarkYellow "/[$n1;$v1]"
                    }
                }
            }

            $Name   = 'IP Address'
            $Type   = 'String'
            $Value  = "" ; 

            $r = Get-Random -Maximum 4 -Minimum 1
            switch($r){
                1  {$Value = "192.168.$(Get-Random -Maximum 255 -Minimum 1).$(Get-Random -Maximum 255 -Minimum 1)" ; }
                2  {$Value = "$(Get-Random -Maximum 99 -Minimum 1).$(Get-Random -Maximum 99 -Minimum 1).$(Get-Random -Maximum 255 -Minimum 1).$(Get-Random -Maximum 255 -Minimum 1)" ; }
                3  {$Value = "10.0.$(Get-Random -Maximum 100 -Minimum 1).$(Get-Random -Maximum 255 -Minimum 1)" ; }
            }
            
            if(-not $TestMode){
                New-Item -Path $p -Force | Out-null
                New-ItemProperty -Path $p -Name $Name -Value $Value -PropertyType $Type  | Out-null
                
                Write-Host "+ $Name / " -n -f Blue
                Write-Host "$Value" -n -f Yellow
                Write-Host "`t`t[$rel]" -f Gray
           }else{
                Write-Host -n -f DarkRed "[TestMode] "
                Write-Host -n -f Gray "$p"
                Write-Host -f DarkYellow "/[$Name;$Value]"
            }
            $TotalEntries++
        }

        Write-Host -f DarkCyan "+ IPADDRESS ENTRIES : $TotalEntries"
        if($BogusEntries){ Write-Host -f DarkYellow "+ BOGUS ENTRIES : $($Noise.Count)" }
        $TotalEntries += $($Noise.Count)
        Write-Host -f Red "+ TOTAL ENTRIES : $TotalEntries"

        if($StartRegEd){
            $TkExe = (Get-Command "taskkill.exe").Source
            &"$TkExe" -IM "regedit.exe"
            [string]$LastKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit"
            [string]$LastKeyValue = "LastKey"
            $RegPath = $p.Replace('HKCU:\','Ordinateur\HKEY_CURRENT_USER\')
            Set-ItemProperty -Path "$LastKeyPath" -Name "$LastKeyValue" -Value "$RegPath"      
            $RegEditExe = (Get-Command "regedit.exe").Source
            &"$RegEditExe"        
        }
    }catch{
        Write-Error "$_"
    }
```