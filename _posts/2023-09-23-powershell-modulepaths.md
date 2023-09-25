---
layout: post
title:  "Get the PowerShell Module Paths"
summary: "PowerShell Module Paths and Status"
author: guillaume
date: '2023-09-23'
category: ['powershell','scripts', 'update', 'modules', 'psmodulepath']
tags: powershell, scripts, 'modules', 'psmodulepath'
thumbnail: /assets/img/posts/generic.png
keywords: powershell, scripts, modules, psmodulepath
usemathjax: false
permalink: /blog/powershell-modulepaths/

---

## Overview

List the PowerShell Module Paths, if they are writeable and the number of modules they contain.


```powershell

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

  function Get-AllModulePaths{
      [CmdletBinding(SupportsShouldProcess)]
      Param()
      $VarModPath=$env:PSModulePath
      $Paths=$VarModPath.Split(';').ToLower()
      $WritablePaths=(Get-WritableModulePath).Path.ToLower()
      $Modules = [System.Collections.ArrayList]::new()
      ForEach($dir in $Paths){
          if(-not(Test-Path $dir)){ continue;}
          $Childrens = (gci $dir -Directory)
          $Mod = [PSCustomObject]@{
                  Path            = $dir
                  Writeable        = $WritablePaths.Contains($dir)
                  Modules         = $Childrens.Count
              }
          $Null = $Modules.Add($Mod)
      }
      return $Modules
  }

```
-------------------


## Performance Test Results


<br>


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/modules.png" alt="table" />
</center>
<br>
