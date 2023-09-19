---
layout: post
title:  "Using WinGet in PowerShell"
summary: "Module that Facilitates the Usage of WinGet in PowerShell"
author: guillaume
date: '2021-08-09'
category: ['powershell','scripts', 'winget']
tags: powershell, scripts, winget
thumbnail: /assets/img/posts/WinGet/1.png
keywords: winget, powershell
usemathjax: false
permalink: /blog/powershell-invoke-parse-winget/

---

### User Request => use WinGet to list the New available versions for specific software </h3>


---------------------------------------------------------------------------------------------------------

The project's traces it's origins from a [Reddit post](https://www.reddit.com/r/PowerShell/comments/xf7y00/need_help_parsing_text/)

A [Reddit User](https://www.reddit.com/user/pjmarcum/) posted a question regarding WinGet. He wanted to parse text returned by Winget, basically use WinGet in PowerShell. [Link to Post](https://www.reddit.com/r/PowerShell/comments/xf7y00/need_help_parsing_text/). And upon loking at this, I was completely flabbergasted to see that theres a major disconnect between PowerShell and the WinGet application. Both are Microsoft products, still it's like they are completely created
with absolute ignorance of each other existance.

Personally, I put the blame on the WinGet dev team. 

WinGet is a command-line tool but it seems zero effort was put in to make it easy to integrate with other tools.

Example: Upon executing long network operations, WinGet will display a progress bar that contains non-ascii characters (Unicode specal characters). 
It makes for a very pretty progress bar, but it will mess up any scripts that is trying to parse the program output. Moreover, there's no options
to disable that special progress bar, we can only change the colors of it. This tells me that the developers are not concerned about the integration
of WinGet in external processes like Continous Integrations or PowerShell...

It is with this in mind that I created a small module on top of WinGet that parse the command output and creates PSObjects that are easily useable 
by the user.


### Define the Scripts Requirements 

We want to retreive :



- the list of installed applications along with their versions 
- the latest version number for applications when an update is available 
- the applications unique identifiers 
- the applications name 


In order to get these informations, we will need to use the following WinGet commands

- list 
- upgrade 
- search 


We therefore implements a module that will proxy b etween us and WinGet and supports those commands, along with the export command that
may prove usefull in the future.



### The Basics </h3>

Invoke the WinGet command with the different options that we need to support, get the exit status, filter out the unwanted characters outputted by WinGet, 
parse all the data outputted by WinGet in coherent data structures that are useable by the caller. All that and we need to have error management.


#### Invoke-PSWinGet 

This function gets the location WinGet, invokes the command, filter out the unwanted output and pass down the returned data to additional processing functions.


```powershell


	Function Invoke-PSWinGet{

	    <#  
	        .Synopsis
	           invoke the WinGet command in PowerShell and parse the command output.
	    #>

	    [CmdletBinding(SupportsShouldProcess)]
	    param(

	        [ValidateScript({
	            $supported_commands = @('l','list', 'installed','s','search', 'online','u','update', 'upgrade','e','export', 'h', 'help',  '/h',  '-h', '-?')
	            $user_entry = $_.ToLower()
	            $Ok = $supported_commands.Contains($user_entry)
	            if(-Not ($Ok) ){
	                throw "command not supported ($user_entry). Supported Commands are list', 'search', 'upgrade', 'export' and 'help'"
	            }
	            return $true 
	        })]
	        [Parameter(Mandatory=$true,Position=0)]
	        [Alias('c', 'cmd')]
	        [String]$Command,
	        [Parameter(Mandatory=$false,Position=1)]
	        [String]$Option,
	        [Parameter(Mandatory=$false)]
	        [switch]$HideCursor,
	        [Parameter(Mandatory=$false)]
	        [switch]$Quiet
	    )


	    $WinGetPackageVersionClassPath = Get-WinGetPackageVersionClassPath
	    if(Test-Path $WinGetPackageVersionClassPath -PathType Leaf){
	        . "$WinGetPackageVersionClassPath" 
	    }

	    #requires -version 5.0

	    $Script:OutputHack=$False
	    if($HideCursor){
	        $Script:OutputHack=$True
	    }
	    # =================================================================
	    # sanity checks : validate that dependencies are registered...
	    # =================================================================
	    try{
	        [WinGetPackageVersion]$testver = [WinGetPackageVersion]::new("1.0.0")
	        if($testver.Major -ne 1){ throw "Error with WinGetPackageVersion"}
	        if((Test-Path "$(Get-WinGetExePath -Verbose:$False)") -ne $true){ throw "Error with WinGetExePath"}
	    }catch{
	        Write-Error "$_"
	        return
	    }

	    # =================================================================
	    # cmd type: easier when its an enum
	    # =================================================================
	    try{
	        Add-Type -TypeDefinition @"
	           public enum CmdType
	           {
	                invalid = 0,
	                installed,
	                online,
	                upgradable,
	                export
	           }
	"@
	    }catch{
	        Write-Verbose "Type CmdType already added"
	    }


	    [CmdType]$CmdType = [CmdType]::invalid
	    $WinGetExe = Get-WinGetExePath

	    # try my best to fix the OUTPUT from WinGet...
	    $e = "$([char]27)"
	    if($Script:OutputHack){
	        #hide the cursor
	        Write-Host "$e[?25l"  -NoNewline  
	        write-host "$($e)[s" -NoNewline
	        Write-Host "$e[u" -NoNewline  
	    }
	    ########################################
	    # REGEX USEFUL FOR PARSING MY OUTPUT....
	    # package info (well-formed)
	    $ptrn_pkinf = "^(?<Name>[\w\(\) \. \-a-zA-Z0-9\*]{0,35})(\s+)(?<Id>[\.\-a-zA-Z0-9]{0,38})(\s+)(?<Version>[\.\-a-zA-Z0-9]{0,38})(\s+)(?<NewVersion>[\.\-a-zA-Z0-9]{0,38})"
	    # package title
	    $ptrn_title = "^(?<Name>Name)(\s*)(?<Id>Id)(\s*)(?<Version>Version)(\s*)(?<Available>Available)"
	    # unicode garage that I experiened... may be different at your place. I filter out the trash with this.
	    $poo_unicd  ="^(?<UNICODE00>[\u00C0-\u00FF]*)(\s+)(?<UNICODE01>[\u00C0-\u00FF]*)(\s*)(?<Version>[\.0-9]{0,5})(\s*)(?<LatestVersion>[\.0-9]{0,5})"
	    # ascii garbage foobar
	    $poo_ascii  ="^(?<ASCII00>[\x2D]*)(\s+)(?<ASCII01>[\x2D]*)(\s*)(?<ASCII02>[\x2D]*)(\s*)(?<ASCII03>[\x2D]*)"
	    $winget_cmd_results = [system.collections.arraylist]::new()

	    $categories = [system.collections.arraylist]::new()
	    [void]$categories.Add('Name')
	    [void]$categories.Add('Id')
	    [void]$categories.Add('Version')
	    [void]$categories.Add('Available')
	    [void]$categories.Add('Source')

	    if($Quiet){
	        [version]$ver = Get-WinGetVersion
	        $vstr = $ver.ToString()
	        Write-Verbose "using winget v$vstr" 
	    }else{
	        Out-Banner
	    }
	    
	    switch($Command.ToLower()){


	        { 'l','list', 'installed' -eq $_ }   {
	            [CmdType]$CmdType = [CmdType]::installed

	            # Call command AND PARSE the output
	            &"$WinGetExe"  "list" "--accept-source-agreements" | out-string -stream | foreach-object{ 
	                $line = "$_`n"
	                # NICE TO HAVE, replace the PROGRESS characters... suck but no go with MSPOWERSHELLv5, just works with core. Fuck it.
	                #$line = $line.Replace("-\\|/┤┘┴└├┌┬┐⠂-–—–-", "$e[u")
	                if(($line -notmatch $poo_unicd) -and ($line -notmatch $poo_ascii) ){ 
	                    if($line -match $ptrn_title) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }elseif($line -match $ptrn_pkinf) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }
	                }
	            }
	        }


	        { 's','search', 'online' -eq $_ }    {
	            [CmdType]$CmdType = [CmdType]::online
	            if($PSBoundParameters.ContainsKey('Option') -eq $False){ throw "Command 'search/online' requires search argument"}
	            $categories = [system.collections.arraylist]::new()
	            [void]$categories.Add('Name')
	            [void]$categories.Add('Id')
	            [void]$categories.Add('Version')
	            [void]$categories.Add('Match')
	            [void]$categories.Add('Source')
	            $ptrn_title = "^(?<Name>Name)(\s*)(?<Id>Id)(\s*)(?<Version>Version)(\s*)(?<Match>Match)(\s*)(?<Source>Source)"
	            $ptrn_pkinf = "^(?<Name>[\w\(\) \. \-a-zA-Z0-9\*]{0,35})(\s+)(?<Id>[\.\-a-zA-Z0-9]{0,38})(\s+)(?<Version>[\.\-a-zA-Z0-9]{0,38})(\s+)(?<Match>[\:\-a-zA-Z0-9 ]{0,38})(\s+)(?<Source>[a-zA-Z0-9]{0,10})"

	            # Call command AND PARSE the output
	            &"$WinGetExe"  "search" "$Option" "--accept-source-agreements" | out-string -stream | foreach-object{ 
	                $line = "$_`n"
	                # NICE TO HAVE, replace the PROGRESS characters... suck but no go with MSPOWERSHELLv5, just works with core. Fuck it.
	                #$line = $line.Replace("-\\|/┤┘┴└├┌┬┐⠂-–—–-", "$e[u")
	                if(($line -notmatch $poo_unicd) -and ($line -notmatch $poo_ascii) ){ 
	                    if($line -match $ptrn_title) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }elseif($line -match $ptrn_pkinf) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }
	                }
	            }
	        }


	        { 'u','update', 'upgrade' -eq $_ } {
	            [CmdType]$CmdType = [CmdType]::upgradable
	            &"$WinGetExe"  "upgrade" "--include-unknown" "--accept-source-agreements" | out-string -stream | foreach-object{ 
	                $line = "$_`n"
	                # NICE TO HAVE, replace the PROGRESS characters... suck but no go with MSPOWERSHELLv5, just works with core. Fuck it.
	                #$line = $line.Replace("-\\|/┤┘┴└├┌┬┐⠂-–—–-", "$e[u")
	                if(($line -notmatch $poo_unicd) -and ($line -notmatch $poo_ascii) ){ 
	                    if($line -match $ptrn_title) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }elseif($line -match $ptrn_pkinf) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }
	                }
	            }
	        }

	        { 'e','export' -eq $_ } {
	            [CmdType]$CmdType = [CmdType]::export
	            if($PSBoundParameters.ContainsKey('Option') -eq $False){ throw "Command 'export' requires file path argument"}
	            $upgrade_cmd_results = [system.collections.arraylist]::new()
	            # Call command AND PARSE the output
	            &"$WinGetExe"  "list" "--accept-source-agreements" | out-string -stream | foreach-object{ 
	                $line = "$_`n"
	                # NICE TO HAVE, replace the PROGRESS characters... suck but no go with MSPOWERSHELLv5, just works with core. Fuck it.
	                #$line = $line.Replace("-\\|/┤┘┴└├┌┬┐⠂-–—–-", "$e[u")
	                if(($line -notmatch $poo_unicd) -and ($line -notmatch $poo_ascii) ){ 
	                    if($line -match $ptrn_title) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }elseif($line -match $ptrn_pkinf) { 
	                        [void]$winget_cmd_results.Add($line);  
	                    }
	                }
	            }
	            &"$WinGetExe"  "upgrade" "--include-unknown" "--accept-source-agreements" | out-string -stream | foreach-object{ 
	                $line = "$_`n"
	                # NICE TO HAVE, replace the PROGRESS characters... suck but no go with MSPOWERSHELLv5, just works with core. Fuck it.
	                #$line = $line.Replace("-\\|/┤┘┴└├┌┬┐⠂-–—–-", "$e[u")
	                if(($line -notmatch $poo_unicd) -and ($line -notmatch $poo_ascii) ){ 
	                    if($line -match $ptrn_title) { 
	                        [void]$upgrade_cmd_results.Add($line);  
	                    }elseif($line -match $ptrn_pkinf) { 
	                        [void]$upgrade_cmd_results.Add($line);  
	                    }
	                }
	            }
	        }
	        
	        { 'h','help', '?' -eq $_ }      { Out-Usage ; return } 
	        default                         { Out-Usage ; return    } 
	    } # switch
	    
	    if($Script:OutputHack){
	        #restore scrolling region
	        Write-Host "$e[s$($e)[r$($e)[u" -NoNewline
	        #show the cursor
	        Write-Host "$e[?25h" 
	    }


	    $software_list_res = [system.collections.arraylist]::new()
	    $LatestVersion = $CmdType -eq [CmdType]::upgradable
	    $software_list_res = Convert-ArrayToAppInfoObjects $winget_cmd_results $categories -LatestVersion:$LatestVersion
	    
	    if($CmdType -eq [CmdType]::export){
	        $software_list_upgradable = [system.collections.arraylist]::new()
	        $software_list_upgradable = Convert-ArrayToAppInfoObjects $upgrade_cmd_results $categories -LatestVersion:$true

	        $software_list_export = [system.collections.arraylist]::new()
	        $IdCheckList = $software_list_upgradable.Id
	        ForEach($app in $software_list_res){
	            $pkg_data = [PSCustomObject]@{
	                Name            = $app.Name
	                Id              = $app.Id
	                Version         = $app.Version.ToString()
	                UpdatedOn       = (Get-Date).GetDateTimeFormats()[33]
	            }
	            $appid = $app.Id
	            [string]$avail_ver = "0.0.0"
	            $new_version_availale = $false
	            if($IdCheckList.Contains($appid)){
	                $new_version_availale = $true
	                $obj = $software_list_upgradable | where -Property Id -eq $appid | select -Unique | select -ExpandProperty LatestVersion
	                if($obj -eq $Null){ throw "Error when merging datatables..."}
	                if($($obj.GetType().Name) -eq 'WinGetPackageVersion'){
	                    $avail_ver = $obj.ToString()
	                }else{
	                    $avail_ver = $obj
	                }
	            }
	            $pkg_data | Add-Member -NotePropertyName NewVersionAvailable -NotePropertyValue $new_version_availale
	            $pkg_data | Add-Member -NotePropertyName LatestVersion -NotePropertyValue $avail_ver

	            [void]$software_list_export.Add($pkg_data)
	        }

	        $parsed_json = $software_list_export | ConvertTo-Json
	        if(Test-Path $Option -PathType Leaf){ 
	            write-host "WARNING! " -f DarkRed -n ; 
	            write-host "File `"$Option`" already exists! . Overwite (y/N)" -f DarkGray -n ; 
	            
	            $a=Read-Host -Prompt "?" ; 
	            if($a -notmatch "y") {
	                write-host "Exiting on user request. " -f DarkYellow
	                return $software_list_export;
	            }  
	        }

	        $Null = New-Item -Path $Option -ItemType file -Force -ErrorAction Ignore
	        Write-Verbose "✅ Writing $Option"
	        Set-Content -Path $Option -Value $parsed_json -Force
	        return $software_list_export;
	    }
	    
	    return $software_list_res;

	}


```




#### Convert-ArrayToAppInfoObjects 

This function receives an arraylist, which represents a line-by-line output returned by WinGet and uses 
regular expressions to parse it and deals with erros.


```powershell


	function Convert-ArrayToAppInfoObjects {        # NOEXPORT
	<#  
	    .Synopsis
	       Repair-WinGetOutput : Gets a string and repair it.
	#>

	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Mandatory=$true, position=0)]
	        [system.collections.arraylist]$winget_cmd_results,
	        [Parameter(Mandatory=$true, position=1)]
	        [system.collections.arraylist]$categories,
	        [Parameter(Mandatory=$false)]
	        [switch]$LatestVersion
	           
	    )
	    $software_list = [system.collections.arraylist]::new()
	    $IndexLine = $winget_cmd_results |  Where-Object {($_ -match $categories[0]) -And ($_ -match $categories[1]) -And ($_ -match $categories[1]) -And ($_ -match $categories[2]) -And ($_ -match $categories[3]) } | Out-String
	    
	    if($IndexLine -eq $Null){ throw "Can parse command output"}

	    # Indexes...
	    $id_start = $IndexLine.IndexOf($categories[1])
	    $id_verstart = $IndexLine.IndexOf($categories[2])
	    $id_lastver = $IndexLine.IndexOf($categories[3])
	    $id_srcstart = $IndexLine.IndexOf($categories[4])

	    # Max lenght. I did this ecause some packages had HUGE NAMEs, like 'Windows Software Development Kit - WINDOWS SDK - DEV' so I cut them down
	    $max_len_name = $id_start - 10
	    $max_len_id =  $id_verstart-($id_verstart - $id_start) - 5
	    $max_len_ver =  14


	    $winget_cmd_results | Select-Object -Skip 1   | Select-Object -SkipLast 1 | ForEach-Object {
	        $appname = $_.Substring(0, $id_start).TrimEnd()
	        $pattern="^(?<GROUPNAME>[\w\(\) \. \-a-zA-Z0-9\*]{0,35})"
	        $appname = Repair-WinGetOutput $appname -max_len $max_len_name # -pattern $pattern

	        $appid = $_.Substring($id_start, $id_verstart - $id_start).TrimEnd()
	        $pattern = "^(?<Name>[\w\(\) \. \-a-zA-Z0-9\*]{0,35})(\s+)(?<GROUPNAME>[\.\-a-zA-Z0-9]{0,38})"
	        $appid = Repair-WinGetOutput $appid -max_len $max_len_id -pattern $pattern

	        [string]$curr_ver_str = $_.Substring($id_verstart, $id_lastver - $id_verstart).TrimEnd()
	        if("$curr_ver_str" -eq "Unknown"){  $curr_ver_str = "1.0.0"}
	        $pattern = "^(?<GROUPNAME>[\.0-9]{0,17})"
	        $curr_ver_str = Repair-WinGetOutput $curr_ver_str -max_len $max_len_ver -is_version # -pattern $pattern
	        [WinGetPackageVersion]$curr_ver = [WinGetPackageVersion]::new($curr_ver_str)
	        
	        [string]$avail_ver_str = '0.0.0'
	        if($LatestVersion){
	            [string]$avail_ver_str = $_.Substring($id_lastver, $id_srcstart - $id_lastver).TrimEnd()
	            $pattern = "^(?<GROUPNAME>[\.0-9]{0,17})"
	            $avail_ver_str = Repair-WinGetOutput $avail_ver_str -max_len $max_len_ver -is_version # -pattern $pattern
	        }
	        try{
	            $pkg_data = [PSCustomObject]@{
	                Name            = [string]$appname
	                Id              = [string]$appid
	                Version         = [WinGetPackageVersion]$curr_ver
	            }
	        }catch{
	            Write-Warning "Parsing error: `"$_`""
	        }
	        if($LatestVersion){
	            #[WinGetPackageVersion]$avail_ver = [WinGetPackageVersion]::new($avail_ver_str)
	            $pkg_data | Add-Member -NotePropertyName LatestVersion -NotePropertyValue $avail_ver_str
	        }
	        [void]$software_list.Add($pkg_data)
	    }

	    $software_list
	}

```


#### Class WinGetPackageVersion 


Next-up, we need to look into the ```version``` property representation in our code. See, 
because we are working with different Microsoft products that a developed seemingly independantly
we cannot share the version data without creating a common container that will be understood by our module
and by WinGet.

Here's a clear example of what I'm saying: in PowerShell, we represent a product version using the [system.version] container.
The latter has 4 properties: Major, Minor , Build , Revision. Unfortunately the data returned by WinGet has version structures
that are incompatibe (see the image below) 


<img class="card-img-top-restricted-50"
     src="/assets/img/posts/WinGet/PowerShellVersions.png"
     alt="PowerShellVersions" />


<img class="card-img-top-restricted-50"
     src="/assets/img/posts/WinGet/WinGetVersions.png"
     alt="WinGetVersions" />


This is the rationale for the implementation of the ```WinGetPackageVersion``` PowerShell type. We basically created a C# class
representing a version number with more properties.

<mark>Notes</mark> since the version type needs to implement comparison operators, we need to inherit from the ```IComparable``` class.
Secondly I added string properties in the class that represent the RegEx expression that will be used to parse version from strings.


#### Version Parsing 

<img class="card-img-top-restricted-60"
     src="/assets/img/posts/WinGet/tryformat.png"
     alt="Verion Parsing" />


[WinGetPackageVersion Class on Github](https://github.com/arsscriptum/PowerShell.Module.InvokeWinGet/blob/main/src/WinGetPackageVersion.ps1)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**


### Documentation - How the Use 


<blockquote>
<p>usage: <strong>Invoke-PSWinGet  [command] [options] <-Quiet -HideCursor></strong></p>
<p></p>
<p>The following commands are available: </p>
<p>        <mark>help</mark>         Help </p>
<p>        <mark>l | list</mark>     Display installed packages. </p>
<p>        <mark>u | upgrade</mark>  Shows and performs available upgrades </p>
<p>        <mark>s | search</mark>   Find and show basic info of packages </p>
<p>        <mark>export</mark>       Exports a list of the installed packages </p>
</blockquote>



#### Usage Examples 

<em>Command : list</em>

Description: Get list of installed software

```
    pswinget <list>
```

<em>Command : search</em>

Description: Get list of software online (not installed)

```
    pswinget <search|online> <search term>
```



<em>Command : upgrade</em>

Description:  Get list of software with a new version available (upgradable)

```
    pswinget <search> <search term>
```


<em>Command : export</em>

Description:  Export list of installed software with information if theres a new version available (in a json file)

```
    pswinget export "PATH to File"
```


<em>More details on the export command</em>

See an exampe usage below...


```
    pswinget export "c:\Temp\apps.json"

    # Then later...
    $AppsInfos = Get-Content "c:\Temp\apps.json" | ConvertFrom-Json
    $AppsInfos | % { if($_.NewVersionAvailable) { 
    	Write-Host "Yo $ENV:USERNAME! " -f DarkRed -n
    	Write-Host " YUO NEED TO UPDATE $($_.Name)" -f DarkYellow 
    }}
```