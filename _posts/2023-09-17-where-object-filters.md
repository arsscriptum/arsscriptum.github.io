---
layout: post
title:  "PowerShell - Where-Object Complex Filters"
summary: "Using a scriptblock to leverage powerful filtering logic with Where-Object"
author: guillaume
date: '2023-09-17'
category: ['powershell','scripts', 'regex', 'filters', 'where']
tags: powershell, scripts, regex, where, filters
thumbnail: /assets/img/posts/whereobject-filters/main.png
keywords: powershell, scripts, filters, where
usemathjax: false
permalink: /blog/whereobject-filters/

---


## Overview - Where-Object - Complex Filters using ScriptBlocks

People are often not aware of the extensibility of the ```Where-Object``` cmdlet and how you can leverage it's power to create complex filters.

I'm talking about creating a ```scriptblock``` containing the filtering logic and using it in your command

For Example: here, let's create a **scriptblock** named ```$custom_gcifilter```;
1. In it, I declare an array of pre-defined strings
2. I have a boolean variable named ```$valid``` that will be returned by the scriptblock: ```$False``` and the value is filtered out from the ```Where``` clause, ```$True``` it is included
3. I declare a variable **name** ( ```$name=$_.Name``` ) . Note the ```$_``` . This represent the current instance in the pipeline.

This line checks if the current instance has a name included in the ```$a``` array and if the instance was created more than 10 minutes ago. if so, it sets the ```$valid``` to ```$True```

```
  if(($($ts.Minutes) -gt 10) -and ($a.Contains($name))) { $valid=$True }
```

Complete filer script block

```
  $custom_gcifilter = {
	$a = @('microsoft.com','google.com','videotron.com','bell.ca','military.com','panasonic.com')
    $valid=$False;$name=$_.Name;[DateTime]$dt=$_.CreationTime;[timespan]$ts = [datetime]::now - $dt;
	if(($($ts.Minutes) -gt 10) -and ($a.Contains($name))) { $valid=$True }
    $valid
  }
```

Now, we use it like so:

```
  Get-ChildItem -Path "." -Recurse | Where $custom_gcifilter
```

## Advanced Example: Filter Directories based on Permissions

Let's crank the level a bit. We need to filter directories based on the permissions we have on them. This is a bit trickier because there is multiple data sets to cross check.

1. The user specifies the permissions to have on the directories listed, example ```@('Modify','FullControl','Write')```
2. We need to get the current user group appartenance.
3. For each paths, we get the *FileSystemRights* and *IdentityReference*
4. We check if the *FileSystemRights* match the user-specified permissions
5. We check if the *IdentityReference* is included in our *current user group list*

Here's the code:

```
	[string[]]$Permissions=@('Modify','FullControl','Write')

    $aclfilter_perm = {
        $ir=$_.IdentityReference;$fsr=$_.FileSystemRights.ToString();$hasright=$false;
        ForEach($pxs in $Permissions){ if($fsr -match $pxs){$hasright=$True;}};
        $GroupList.Contains($ir) -and $hasright
    }

	# Get a dir to check
	$CurrentPath = (Get-Location).Path
	(Get-Acl $CurrentPath).Access | Where $aclfilter_perm
```

## Wrapping things up: check directory permissions

Here's a pratical example: listing the ```PSModule``` folders and checking the ones we have access to:


```

  function Get-WritableModulePath{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Permissions")]
        [string[]]$Permissions=@('Modify','FullControl','Write')
    )
    $VarModPath=[System.Environment]::GetEnvironmentVariable("PSModulePath")
    $Paths=$VarModPath.Split(';')

    Write-Verbose "Get-WriteableFolder from $Path and $PathsCount childs"
    # 1 -> Retrieve my appartenance (My Groups)
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $groups = $id.Groups | foreach-object {$_.Translate([Security.Principal.NTAccount])}
    $GroupList = @() ; ForEach( $g in $groups){  $GroupList += $g ; }
    Sleep -Milliseconds 500
    $PathPermissions =  [System.Collections.ArrayList]::new()   

    $aclfilter_perm = {
        $ir=$_.IdentityReference;$fsr=$_.FileSystemRights.ToString();$hasright=$false;
        ForEach($pxs in $Permissions){ if($fsr -match $pxs){$hasright=$True;}};
        $GroupList.Contains($ir) -and $hasright
    }
    ForEach($p in $Paths){
        if(-not(Test-Path -Path $p -PathType Container)) { continue; }
        $perm = (Get-Acl $p).Access | Where $aclfilter_perm | Select `
                                 @{n="Path";e={$p}},
                                 @{n="IdentityReference";e={$ir}},
                                 @{n="Permission";e={$_.FileSystemRights}}
        if( $perm -ne $Null ){
            $null = $PathPermissions.Add($perm)
        }
    }

    return $PathPermissions
  }
```

### Note

In the command below

```
   $perm = (Get-Acl $p).Access | Where $aclfilter_perm | Select `
      @{n="Path";e={$p}},
      @{n="IdentityReference";e={$ir}},
      @{n="Permission";e={$_.FileSystemRights}}
```

Note that the ```Select``` statement is using variables declared in the ```scriptblock``` used in the ```Where-Object``` clause. When you declare a variable in the pipeline, it can be used later on, in other clauses in the pipeline.

-------------------

<br>


## Get the code 

[ComplexFilters on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/ComplexFilters)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**