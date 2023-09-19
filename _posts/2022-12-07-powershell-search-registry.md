---
layout: post
title:  "Search Registry with PowerShell"
summary: "Script to Search the Windows Registry with PowerShell"
author: guillaume
date: '2022-12-07'
category: ['powershell','registry']
tags: powershell, registry
thumbnail: /assets/img/posts/search_reg/1.png
keywords: powershell, registry
usemathjax: false
permalink: /blog/powershell-registry-search

---
# Search the Registry

This is in response to [/u/mudderfudden](https://www.reddit.com/user/mudderfudden/) who asked in this [post](https://www.reddit.com/r/PowerShell/comments/zgbqt4/how_can_i_search_entire_registry_for_a_key_and/)how he could locate a specific string in the registry (key name, value name or data). Moreover, he wants to search in multiple hives at once.

## Search-Registry function

This function is based on ```Get-ChildItems``` to list registry keys and depending on where the user looks, will compare using regex for
- Key Name
- Value Name (the id of the value)
- Data

It returns a list of objects with following properties: Registry Key Path, Reason, matched String.

## Usage Example

### Basis 

This will search in "HKLM:\SYSTEM\CurrentControlSet\Services" for the string "svchost". Since no other arguments were specified, we look for the  searched string in every key names, value names and value data.

```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "svchost"
```

The returned list contains strings found in 3 categories, if we want to get a subset of those results, we can specify where to search like this:

The same command but with ```-KeyName``` will only return the entries where the key name match "svchost"

```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "svchost" -KeyName
```

The same command but with ```-PropertyValue``` will only return the entries where the value data match "svchost"

```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "svchost" -PropertyValue
```

### REGEX

Since search uses the ```-match``` operator, it does a regex matching. ***So all RegexEx operator applies***

#### Special Characters

Here the ```^``` and the ```$``` characters are used to specify the start and end of the string so that we only search for data containing "Core"

```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "^Core$" -PropertyValue
```

#### Multiple Words

Let's search the same path for two (2) value names, hence searching 2 words. Like 'Start' and 'Type'. 
The Regex expression is "(Start)|(Type)" or plain "Start|Type"


```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "Start|Type" -PropertyValue

    Key                                                                                            Reason    String
    ---                                                                                            ------    ------
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vpcivsp                                   PropertyValue Start
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vsmraid                                   PropertyValue Start
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VSS                                       PropertyValue Type
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VSStandardCollectorService150             PropertyValue ServiceSidType
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\gupdate                                   PropertyValue DelayedAutostart   
```

Oups, we got ```ServiceSidType``` and ```DelayedAutostart``` and were not looking for those. Use Regex to specify start ant end of string then:


```powershell
    Search-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -SearchRegex "^Start$|^Type$" -PropertyValue

    Key                                                                                            Reason    String
    ---                                                                                            ------    ------
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vpcivsp                                   PropertyValue Start
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vsmraid                                   PropertyValue Start
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VSS                                       PropertyValue Type

```

***MUCH BETTER***


### Registry Hives

Those are the registry hives that are searchable. 
- HKEY_LOCAL_MACHINE
- HKEY_CURRENT_USER
- HKEY_CLASSES_ROOT
- HKEY_CURRENT_CONFIG
- HKEY_USERS
- HKEY_PERFORMANCE_DATA

But the ones used by a regular users are only those 3:

- HKEY_LOCAL_MACHINE
- HKEY_CURRENT_USER
- HKEY_CLASSES_ROOT

#### Search multiple Hives like so:

```powershell
    $Hives = @('HKCU:\', 'HKLM:\')
    Search-Registry -Path $Hives -SearchRegex "Wavebrowser|Wavsor" -Recurse -SilentErrors
```

### Access Errors in Registry

Access Errors are handled gracecfully, it will not stop the search.

You will get somethis like this.

```powershell
    Search-Registry -Path $RootRegistryPath -SearchRegex "searchstring" -Recurse

    WARNING: Access Error: HKEY_CURRENT_USER\SOFTWARE\DevelopmentSandbox
    WARNING: Access Error: HKEY_CURRENT_USER\SOFTWARE\DevelopmentTestTest
    WARNING: Total Access Errors: 2

```

### SilentErrors

Silence Access Errors by using ```-SilentErrors```

```powershell
    Search-Registry -Path $RootRegistryPath -SearchRegex "searchstring" -Recurse -SilentErrors
```


--------------------------------------------------------------------------------------------------------


```powershell

    function Search-Registry { 
    <# 
    .SYNOPSIS 
    Searches registry key names, value names, and value data (limited). 

    .DESCRIPTION 
    This function can search registry key names, value names, and value data (in a limited fashion). It outputs custom objects that contain the key and the first match type (KeyName, PropertyValue, or ValueData). 

    .OUTPUTS
    Returns a list of objects with following properties: Registry Key Path, Reason, matched String

    .EXAMPLE 
    # Search ANY Value Names, Value Data and Key Names matching string "svchost"
    Search-Registry -Path HKLM:\SYSTEM\CurrentControlSet\Services\* -SearchRegex "svchost" 

    .EXAMPLE 
    Search-Registry -Path HKLM:\SOFTWARE\Microsoft -Recurse -PropertyValueRegex "PropertyValue1|PropertyValue2" -ValueDataRegex "ValueData" -KeyNameRegex "KeyNameToFind1|KeyNameToFind2" 

    .EXAMPLE
    # HKEY_CURRENT_USER, HKEY_CLASSES_ROOT, HKEY_LOCAL_MACHINE for strings 'Wavsor' and 'Wavebrowser'
    $RootRegistryPath = @("HKLM:\", "HKCU:\")
    Search-Registry -Path $RootRegistryPath -SearchRegex "Wavebrowser|Wavsor"
    #> 
        [CmdletBinding()] 
        param( 
            [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true, HelpMessage="The Paths to search in")] 
            [Alias("p", "PsPath")] 
            [string[]] $Path, 
            [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true, HelpMessage="Search string regex")] 
            [string] $SearchRegex, 
            [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry key name")] 
            [switch] $KeyName, 
            [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry property name")] 
            [switch] $PropertyName, 
            [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry property value")] 
            [switch] $PropertyValue, 
            [Parameter(Mandatory=$false, HelpMessage="No Errors please")]
            [switch] $SilentErrors,
            [Parameter(Mandatory=$false, HelpMessage="Depth of recursion")]
            [uint32] $Depth,
            [Parameter(Mandatory=$false, HelpMessage="Specifies whether or not all subkeys should also be searched ")]
            [switch] $Recurse
        ) 

        begin { 
            [string] $KeyNameRegex=''
            [string] $PropertyNameRegex=''
            [string] $PropertyValueRegex=''

            $NoSwitchesSpecified = -not ($PSBoundParameters.ContainsKey("KeyName") -or $PSBoundParameters.ContainsKey("PropertyName") -or $PSBoundParameters.ContainsKey("PropertyValue")) 
            Write-Verbose "NoSwitchesSpecified  -> $NoSwitchesSpecified" 

            if ($KeyName -or $NoSwitchesSpecified) { 
                $KeyNameRegex = $SearchRegex
                Write-Verbose "SearchFor  -> KeyName `"$KeyNameRegex`""  
            } 
            if ($PropertyName -or $NoSwitchesSpecified) { 
                $PropertyNameRegex = $SearchRegex
                Write-Verbose "SearchFor  -> PropertyName `"$PropertyNameRegex"
            } 
            if ($PropertyValue -or $NoSwitchesSpecified) { 
                $PropertyValueRegex = $SearchRegex
                Write-Verbose "SearchFor  -> PropertyValue `"$PropertyValueRegex`""  
            } 
             
            
        } 

        process { 
            
            [System.Collections.ArrayList]$Results = [System.Collections.ArrayList]::new()
            foreach ($CurrentPath in $Path) { 
                if($PSBoundParameters.ContainsKey('Depth') -eq $True){
                    $AllObjs = Get-ChildItem $CurrentPath -Recurse:$Recurse -ev AccessErrors -ea silent -Depth $Depth
                }else{
                    $AllObjs = Get-ChildItem $CurrentPath -Recurse:$Recurse -ev AccessErrors -ea silent
                }
                
                $AllObjs | ForEach-Object { 
                        $Key = $_ 

                        if ($KeyNameRegex) {  
                            Write-Verbose ("{0}: Checking KeyNamesRegex" -f $Key.Name)  

                            if ($Key.PSChildName -match $KeyNameRegex) {  
                                $Value = $Key.PSChildName
                                Write-Verbose "  -> Match found! $Value" 
                                [PSCustomObject]$o = [PSCustomObject] @{ 
                                    Key = $Key 
                                    Reason = "KeyName" 
                                    String = $Value
                                }
                                [void]$Results.Add($o)
                            }  
                        } 

                        if ($PropertyNameRegex) {  
                            Write-Verbose ("{0}: Checking PropertyNameRegex" -f $Key.Name) 

                            if ($Key.GetPropertyValues() -match $PropertyNameRegex) {  
                                
                                [string[]]$Names = $Key.GetPropertyValues()
                                $Value = ''
                                FOrEach($name in $Names){
                                    if($name -match $PropertyNameRegex) {
                                       $Value = $name 
                                    }
                                }
                                Write-Verbose "  -> Match found! $Value"
                                [PSCustomObject]$o = [PSCustomObject] @{ 
                                    Key = $Key 
                                    Reason = "PropertyName" 
                                    String = $Value
                                } 
                                [void]$Results.Add($o)
                            }  
                        } 

                        if ($PropertyValueRegex) {  
                            Write-Verbose ("{0}: Checking PropertyValueRegex" -f $Key.Name) 
                            if (($Key.GetPropertyValues() | % { $Key.GetValue($_) }) -match $PropertyValueRegex) {  
                           
                                [string[]]$Names = $Key.GetPropertyValues()
                                $Value = ''
                                FOrEach($name in $Names){
                                    $TestValue = $Key.GetValue($name) 
                                    if($TestValue -match $PropertyValueRegex) {
                                       $Value = $Key.GetValue($name) 
                                    }
                                }
                                Write-Verbose "  -> Match found! $Value"
                                [PSCustomObject]$o = [PSCustomObject] @{ 
                                    Key = $Key 
                                    Reason = "PropertyValue" 
                                    String = $Value
                                } 
                                [void]$Results.Add($o)
                            } 
                        } 
                    } 
            } 

            if($PSBoundParameters.ContainsKey('SilentErrors') -eq $False){
                $AccessErrorsCounts = $AccessErrors.Count
                if($AccessErrorsCounts -gt 0){

                    $AccessErrors | % {
                        Write-Warning "Access Error: $($_.TargetObject)"
                    }
                    Write-Warning "Total Access Errors: $AccessErrorsCounts"
                    
                }
            }

            return $Results
        } 
    } 
```

--------------------------------------------------------------------------------------------------------


### Get the Code

[SearchRegistry on GitHub](https://github.com/arsscriptum/PowerShell.Reddit.Support/tree/main/SearchRegistry)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**