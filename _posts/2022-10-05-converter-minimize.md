---
layout: post
title:  "Compile a Set of PowerShell Scripts in a single PS1"
summary: "Convert a set of PS1 files to Base64 compressed strings and generate a single PS1 file"
author: guillaume
date: '2022-10-05'
category: ['powershell','scripts', 'network']
tags: powershell, scripts, network
thumbnail: /assets/img/posts/converter-minimize/1.png
keywords: network, powershell
usemathjax: false
permalink: /blog/converter-minimize/

---

#### Compile Script 

Function to list the scripts located in a folder and compile them all in a single PS1 file

```powershell
	[CmdletBinding(SupportsShouldProcess)]
	param(
	    [Parameter(Mandatory=$true,Position=0, ValueFromPipeline=$true, 
	        HelpMessage="Path of the files to compile") ]
	    [String]$Path,
	    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true, 
	        HelpMessage="Out file") ]
	    [String]$OutFile
	    )


	#Requires -Version 5


	function Get-Script([string]$prop){
	    $ThisFile = $script:MyInvocation.MyCommand.Path
	    return ((Get-Item $ThisFile)|select $prop).$prop
	}

	$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
	$ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

	#===============================================================================
	# SCRIPT VARIABLES
	#===============================================================================
	$Script:CurrPath                       = $ScriptPath
	$Script:RootPath                       = (Get-Location).Path
	$Script:Time                           = Get-Date
	$Script:Date                           = $Time.GetDateTimeFormats()[19]
	$Script:ScriptList                     = New-Object System.Collections.ArrayList
	$Script:FileHeader                     = "#=================================================`n# Generated on $Script:Date`n#================================================="
	$Script:CompiledScript                 = "$Script:FileHeader`n`n"
	$Script:Converter                      = Join-Path $Script:CurrPath "dependencies\Converter.ps1"
	 

	try{
	    Write-Host "`n`n===============================================================================" -f DarkRed
	    Write-Host "COMPILING SCRIPT FILES in $Path" -f DarkYellow;
	    Write-Host "===============================================================================" -f DarkRed

	    . "$Script:Converter"

	    $Script:CompilationErrorsCount = 0


	    Get-ChildItem -Path "$Path" -File -Filter '*.ps1' -Recurse | ForEach-Object {
	        $Path = $_.fullname
	        $Filename = $_.Name
	        $Basename = (Get-Item -Path $Path).Basename
	        $ScriptName = $Basename

	        # INVALID CHARACTER : - cannot have that in a variable name
	        $BadCharsStr = '-'
	        $BadChars = $BadCharsStr.ToCharArray()
	        $BadChars | % {
	            if($ScriptName -match "$_"){ throw "File name '$ScriptName' contains an invalid character '$_'" }
	        }

	        try {

	            [void] $ScriptList.Add($Basename)
	            Write-Host " - compiling $Filename" -f DarkYellow;
	            # Read script block from module file
	            [string]$ScriptBlock = Get-Content -Path $Path -Raw

	            # Strip out comments
	            $ScriptBlock = Remove-CommentsFromScriptBlock -ScriptBlock $ScriptBlock

	            # Compress and Base64 encode script block
	            $ScriptBlockBase64 = Convert-ToBase64CompressedScriptBlock -ScriptBlock $ScriptBlock

	            $CompiledScript += "# ------------------------------------`n"
	            $CompiledScript += "# Script file - $ScriptName - `n"
	            $CompiledScript += "# ------------------------------------`n"
	            $CompiledScript += "`$ScriptBlock$($ScriptName) = `"$($ScriptBlockBase64)`"`n`n"
	        }catch { 
	            Show-ExceptionDetails($_) -ShowStack
	            $Script:CompilationErrorsCount += 1
	        }
	    }

	    $LoaderBlock = Get-LoaderBlock

	    $CompiledScript += "`n`n$($LoaderBlock)`n`n"

	    Write-Host "Saving to $OutFile" -f DarkYellow;

	    Set-Content "$OutFile" -Value $CompiledScript 

	    Write-Host "Done!" -f DarkGreen;

	}catch{
	    Write-Error $_
	}

```

------------------------------------------------------------------------------------------------------------------------------------------------

<center>
<img class="card-img-top-restricted-60"
     src="/assets/img/posts/converter-minimize/demo.gif"
     alt="Demo" />

</center>

------------------------------------------------------------------------------------------------------------------------------------------------

### Get the code !
[PowerShell.Converter-Minimize on Github](https://github.com/arsscriptum/PowerShell.Converter-Minimize)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**