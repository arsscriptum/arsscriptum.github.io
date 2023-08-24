---
layout: post
title:  "PowerShell GREP: Improving on Select-String"
summary: "Wrapper function to add functionalities to Select-String"
author: guillaume
date: '2021-12-12'
category: ['powershell','scripts', 'grep']
tags: powershell, scripts, grep
thumbnail: /assets/img/posts/grep/1.png
keywords: winget, powershell
usemathjax: false
permalink: /blog/powershell-grep/

---

### Introduction </h3>

For any console sufers like me, having a toolbox filled with basic tools is essential. Linux provides those commands and most IT person, developer and Administrator will know them.
One of the first Linux commands that many users learn is ```grep``` Grep’s provide the ability to search plain text for a RegEx pattern in a set of files. Grep can search files in a given directory or streamed input to output matches.

If you want to ```grep``` in PowerShell, you can use the provided [Select-String cmdlet](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-string?view=powershell-7.2).
Unfortunately, Select-String needs a few improvements in order to be user-friendly like Linux's ```grep```.

I'm not going to explain the basics of ```Select-String``` as there's already tons of articles on it's usage online. Let's focus on how to make our own ```grep``` based on ```Select-String``` instead. That means you are expected
to know how to use Select-String by itself.

---------------------------------------------------------------------------------------------------------

### Define the Scripts Requirements 

We want to add the ability to 



- search recursively in many folders 
- only search specific file types 
- exclude some folders / files from search by name 
- handle files with no newline (like huge css.min) 
- option to get psobjects 




#### search recursively in many folders 

To search recursively in many folders for example, you need also check the current directory and the subfolders (-Recurse) or you need additional filter for files you wanna check, you can use the Get-Childitem before Select-String like this.

```powershell
	Get-ChildItem C:\temp -Filter *.log -Recurse | Select-String "FooBar"
```
#### only search specific file types 

Lets use ```Get-ChidItems``` and add a file filter argument, so that we can filter only certain file types:

```powershell
    # List all files but not those with those words in the name: Foo,Bar,Please,Not,This
    $Filter = '*.log'
    Get-ChildItem "c:\Logs" -File -Filter $Filter | Select-String -pattern $Pattern
```


#### exclude some folders / files from search by name 

To exclude some folders / files from search by name, we can use the ```Get-ChildItems``` and add a ```Where``` clause with ```-notmatch```. See when you want to add multiple ```-notmatch``` condition to a function call, you 
can just separate the different words by a pipe (|) character like this:

```powershell
	# List all files but not those with those words in the name: Foo,Bar,Please,Not,This
	Get-ChildItem "c:\Logs" -File  -Filter $Filter | where FullName -notmatch "Foo|Bar|Please|Not|This" 
```

So we will have somethis like this:

```powershell
    $Exclude = @('words','to','remove')
    [string]$exclude_string = ''
    ForEach($toexclude in $Exclude){
        $exclude_string += "$toexclude|"
    }
    $exclude_string = $exclude_string.Trim('|')
    Write-Verbose "  Excluding this string in names: $exclude_string"
    $SearchList = Get-ChildItem -Path $Path -File -Filter $Filter | where FullName -notmatch "$exclude_string" | Select-String -pattern $Pattern
```


#### Final function 

After we get the ```Select-String``` results and process them so that we don't have screen overflow with huge onle line files, and after we create the option to output a list of psobjects, we get this:


```powershell

function Search-Pattern
{
<#
    .SYNOPSIS
            Cmdlet to find in files (grep)
    .DESCRIPTION
            Cmdlet to find in files (grep)
    .PARAMETER Pattern
            What to look for in the files
    .PARAMETER Extension
            File Extension, just the Extension, no *
    .PARAMETER Path
            Path for search
    .PARAMETER Exclude
            Exclude string array
    .PARAMETER Short
            Output short file names
    .PARAMETER List
            Output as list of psobjects
    .PARAMETER Recurse
            Recurse in subdirectories
    .EXAMPLE
        Search-Pattern -Pattern 'g.png' -Extension "txt"
        Search-Pattern -Pattern 'g.png' -Exclude @("_site","jekyll-metadata","bower_components","jekyll-cache")
#>


    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Position = 0,Mandatory=$true, HelpMessage="Pattern to search for")]
        [Object]$Pattern,

        [Parameter(Mandatory=$false, HelpMessage="File filter")]
        [Alias('f')]
        [string]$Filter = '*.*',

        [Parameter(Mandatory=$false, HelpMessage="Path for search")]
        [Alias('p')]
        [string]$Path,

        [Parameter(Mandatory=$false, HelpMessage="Exclude string array")]
        [Alias('x')]
        [string[]]$Exclude,

        [Parameter(Mandatory=$false, HelpMessage="Output short file names")]
        [Alias('s')]
        [switch]$Short,

        [Parameter(Mandatory=$false, HelpMessage="Output as list of psobjects")]
        [Alias('l')]
        [switch]$List,

        [Parameter(Mandatory=$false, HelpMessage="Recurse in subdirectories")]
        [Alias('r')]
        [switch]$Recurse=$true

    )   

    [system.collections.arraylist]$Results      = [system.collections.arraylist]::new()
    [Microsoft.PowerShell.Commands.MatchInfo[]]$SearchList;
    [string]$CurrentPath = (Get-Location).Path 
    if([string]::IsNullOrEmpty($Path)){
        $Path = $CurrentPath
    }
    
    Write-Verbose "Search-Pattern (my grep): looking for a string in files. Path: $Path"
    Write-Verbose "  Pattern: $Pattern"
    Write-Verbose "  Short: $Short" 
    Write-Verbose "  Recurse: $Recurse" 
    Write-Verbose "  Using Extension filter: $Filter"

    
    if($Exclude.Count -gt 0){
        [string]$exclude_string = ''
        ForEach($toexclude in $Exclude){
            $exclude_string += "$toexclude|"
        }
        $exclude_string = $exclude_string.Trim('|')
        Write-Verbose "  Excluding this string in names: $exclude_string"
        $SearchList = Get-ChildItem -Path $Path -File -Filter $Filter -Recurse:$Recurse | where FullName -notmatch "$exclude_string" | Select-String -pattern $Pattern
    }
    else{
        $SearchList = Get-ChildItem -Path $Path -File -Filter $Filter -Recurse:$Recurse | Select-String -pattern $Pattern 
    }

    ForEach($match in $SearchList){
        $Path = $match.Path
        $Path = $Path.Replace($CurrentPath,'.')
        if($Short){
            $Path = $match.FileName
        }
        $SearchPattern = $Pattern.Replace('\','')
        $Line = $match.Line.Trim()
        $Index = $Line.IndexOf($SearchPattern)
        if($Index -eq -1){$Index = 0}
        $LineNumber = $match.LineNumber
        $Length = $Line.Length
        
        if($Length -gt 80){
            if($Index -gt 80){
                $Line = $Line.SubString($Index -2,$SearchPattern.Length + 15)
            }else{
                $Line = $Line.SubString(0,80)
            }
        }
        $o = [pscustomobject]@{
            Path = $Path
            LineNumber = $LineNumber
            Index = $Index
            Line = $Line
        }
        if($List){
            [void]$Results.Add($o)
        }else{
            Write-Output "$Path`:$LineNumber,$Index`t$Line"
        }
    }
  
    if($List){
        $Results
    }
}

New-Alias -Name 'grep' -Value -Search-Pattern -Force
```

